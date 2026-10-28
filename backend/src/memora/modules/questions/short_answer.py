"""Bounded short-answer claim evaluation.

The MVP uses a deterministic phrase matcher. A model-backed evaluator can
implement `ClaimEvaluator` later, but it may only supply bounded phrase citations.
Claim identity, required status, weight, coverage and the final score are always
derived from the stored rubric by the server.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

from memora.modules.questions.models import ClaimRubricPayload, ClaimRule
from memora.modules.questions.normalization import (
    contains_phrase,
    first_matching_phrase,
    normalize_text,
)


@dataclass(frozen=True, slots=True)
class ClaimEvidence:
    """Untrusted evaluator output limited to phrase citations from the rubric."""

    matched_variant: str | None = None
    contradiction_phrase: str | None = None


@dataclass(frozen=True, slots=True)
class ClaimMatch:
    """Server-derived claim outcome. Evaluators cannot populate these fields."""

    claim_id: str
    required: bool
    weight: Decimal
    matched: bool
    matched_variant: str | None
    contradiction_phrase: str | None


@dataclass(frozen=True, slots=True)
class ClaimEvaluation:
    matches: tuple[ClaimMatch, ...]
    total_required_weight: Decimal
    matched_required_weight: Decimal
    matched_claim_ids: tuple[str, ...]
    missing_required_claim_ids: tuple[str, ...]
    contradiction_claim_ids: tuple[str, ...]
    rejected_claim_ids: tuple[str, ...]

    @property
    def coverage(self) -> Decimal:
        if self.total_required_weight <= 0:
            return Decimal("0")
        return self.matched_required_weight / self.total_required_weight


class ClaimEvaluator(Protocol):
    """Pluggable evaluator boundary for one stored rubric claim."""

    version: str

    def evaluate(self, claim: ClaimRule, normalized_response: str) -> ClaimEvidence: ...


class DeterministicClaimEvaluator:
    """Exact variant and contradiction matcher with no model involvement."""

    version = "deterministic-claim-v1"

    def evaluate(self, claim: ClaimRule, normalized_response: str) -> ClaimEvidence:
        contradiction = first_matching_phrase(
            normalized_response,
            (normalize_text(phrase) for phrase in claim.contradictions),
        )
        if contradiction is not None:
            return ClaimEvidence(contradiction_phrase=contradiction)

        variant = first_matching_phrase(
            normalized_response,
            (normalize_text(phrase) for phrase in claim.variants),
        )
        return ClaimEvidence(matched_variant=variant)


def evaluate_claims(
    rubric: ClaimRubricPayload,
    response: str,
    *,
    evaluator: ClaimEvaluator | None = None,
) -> ClaimEvaluation:
    active = evaluator or DeterministicClaimEvaluator()
    normalized = normalize_text(response)
    matches: list[ClaimMatch] = []
    rejected_claim_ids: list[str] = []
    for claim in rubric.claims:
        evidence, rejected = _bounded_evidence(
            claim,
            active.evaluate(claim, normalized),
            normalized,
        )
        if rejected:
            rejected_claim_ids.append(claim.claim_id)
        matches.append(
            ClaimMatch(
                claim_id=claim.claim_id,
                required=claim.required,
                weight=claim.weight,
                matched=(
                    evidence.matched_variant is not None and evidence.contradiction_phrase is None
                ),
                matched_variant=evidence.matched_variant,
                contradiction_phrase=evidence.contradiction_phrase,
            )
        )

    required = [match for match in matches if match.required]
    return ClaimEvaluation(
        matches=tuple(matches),
        total_required_weight=sum((match.weight for match in required), Decimal("0")),
        matched_required_weight=sum(
            (match.weight for match in required if match.matched), Decimal("0")
        ),
        matched_claim_ids=tuple(match.claim_id for match in matches if match.matched),
        missing_required_claim_ids=tuple(match.claim_id for match in required if not match.matched),
        contradiction_claim_ids=tuple(
            match.claim_id for match in matches if match.contradiction_phrase is not None
        ),
        rejected_claim_ids=tuple(rejected_claim_ids),
    )


def _bounded_evidence(
    claim: ClaimRule,
    raw: object,
    normalized_response: str,
) -> tuple[ClaimEvidence, bool]:
    """Reject any evaluator output that cites a phrase outside the stored rubric.

    A declared phrase is only usable when it also occurs in the normalized
    response. The evaluator can propose evidence, but it cannot invent an answer.
    """

    if not isinstance(raw, ClaimEvidence):
        return ClaimEvidence(), True

    variant_lookup = {normalize_text(phrase): phrase for phrase in claim.variants}
    contradiction_lookup = {normalize_text(phrase): phrase for phrase in claim.contradictions}

    rejected = False
    matched: str | None = None
    if raw.matched_variant is not None:
        if isinstance(raw.matched_variant, str):
            matched = variant_lookup.get(normalize_text(raw.matched_variant))
        if matched is None or not contains_phrase(normalized_response, normalize_text(matched)):
            matched = None
            rejected = True

    contradiction: str | None = None
    if raw.contradiction_phrase is not None:
        if isinstance(raw.contradiction_phrase, str):
            contradiction = contradiction_lookup.get(normalize_text(raw.contradiction_phrase))
        if contradiction is None or not contains_phrase(
            normalized_response, normalize_text(contradiction)
        ):
            contradiction = None
            rejected = True

    if matched is not None and contradiction is not None:
        # Conflicting citations cannot earn credit; the contradiction wins.
        matched = None

    return (
        ClaimEvidence(
            matched_variant=matched,
            contradiction_phrase=contradiction,
        ),
        rejected,
    )
