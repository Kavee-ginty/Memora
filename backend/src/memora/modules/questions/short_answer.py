"""Bounded short-answer claim evaluation.

The MVP uses a deterministic phrase matcher. A model-backed evaluator can
implement `ClaimEvaluator` later without changing grading or persistence, but
model output remains candidate evidence and cannot set scores or confidence
without server validation.
"""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

from memora.modules.questions.models import ClaimRubricPayload, ClaimRule
from memora.modules.questions.normalization import first_matching_phrase, normalize_text


@dataclass(frozen=True, slots=True)
class ClaimMatch:
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

    @property
    def coverage(self) -> Decimal:
        if self.total_required_weight <= 0:
            return Decimal("0")
        return self.matched_required_weight / self.total_required_weight


class ClaimEvaluator(Protocol):
    """Pluggable evaluator boundary for one rubric claim."""

    version: str

    def evaluate(self, claim: ClaimRule, normalized_response: str) -> ClaimMatch: ...


class DeterministicClaimEvaluator:
    """Exact variant and contradiction matcher with no model involvement."""

    version = "deterministic-claim-v1"

    def evaluate(self, claim: ClaimRule, normalized_response: str) -> ClaimMatch:
        contradiction = first_matching_phrase(
            normalized_response,
            (normalize_text(phrase) for phrase in claim.contradictions),
        )
        if contradiction is not None:
            return ClaimMatch(
                claim_id=claim.claim_id,
                required=claim.required,
                weight=claim.weight,
                matched=False,
                matched_variant=None,
                contradiction_phrase=contradiction,
            )

        variant = first_matching_phrase(
            normalized_response,
            (normalize_text(phrase) for phrase in claim.variants),
        )
        return ClaimMatch(
            claim_id=claim.claim_id,
            required=claim.required,
            weight=claim.weight,
            matched=variant is not None,
            matched_variant=variant,
            contradiction_phrase=None,
        )


def evaluate_claims(
    rubric: ClaimRubricPayload,
    response: str,
    *,
    evaluator: ClaimEvaluator | None = None,
) -> ClaimEvaluation:
    active = evaluator or DeterministicClaimEvaluator()
    normalized = normalize_text(response)
    matches = tuple(active.evaluate(claim, normalized) for claim in rubric.claims)
    required = [match for match in matches if match.required]
    return ClaimEvaluation(
        matches=matches,
        total_required_weight=sum((match.weight for match in required), Decimal("0")),
        matched_required_weight=sum(
            (match.weight for match in required if match.matched), Decimal("0")
        ),
        matched_claim_ids=tuple(match.claim_id for match in matches if match.matched),
        missing_required_claim_ids=tuple(match.claim_id for match in required if not match.matched),
        contradiction_claim_ids=tuple(
            match.claim_id for match in matches if match.contradiction_phrase is not None
        ),
    )
