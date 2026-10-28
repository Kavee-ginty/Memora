"""Extraction providers.

Every provider returns candidate evidence only. None of them writes shared
knowledge; the commit service decides what may be retained.
"""

from __future__ import annotations

import base64
import json
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any, Protocol

from memora.modules.ingestion.constants import (
    CANDIDATE_SCHEMA_VERSION,
    CANDIDATE_TYPES,
    DETERMINISTIC_MODEL_KEY,
    EXTRACTION_PROMPT_VERSION,
    MAX_CANDIDATE_TITLE_CHARS,
)

FORMULA_PATTERN = re.compile(r"\b[A-Za-z][A-Za-z0-9_]*\s*=\s*[^.\n]{1,60}")
UNIT_PATTERN = re.compile(
    r"\b\d+(?:\.\d+)?\s?(?:m/s\^?2|m/s|kg|mol|J|N|Pa|W|Hz|V|A|Ω|C|K|m|s|kg/m\^?3)\b"
)


class ExtractionUnavailable(RuntimeError):
    """The configured provider cannot process this source safely."""


class NoExtractableContent(RuntimeError):
    """The provider found no defensible candidate in the source."""


@dataclass(frozen=True, slots=True)
class ExtractedCandidate:
    candidate_type: str
    payload: dict[str, Any]
    source_locator: dict[str, Any]
    confidence: float


class ExtractionProvider(Protocol):
    model_key: str
    prompt_version: str

    def extract(
        self,
        *,
        manual_text: str | None,
        file_bytes: bytes | None,
        media_type: str | None,
        declared_name: str | None,
        aliases: list[dict[str, Any]],
    ) -> list[ExtractedCandidate]:
        pass


class DeterministicExtractionProvider:
    """Bounded alias and pattern matching for manual text.

    This is intentionally conservative: it only recognizes approved curriculum
    aliases and visible formula/unit patterns. It fails closed for binary input.
    """

    model_key = DETERMINISTIC_MODEL_KEY
    prompt_version = EXTRACTION_PROMPT_VERSION

    def extract(
        self,
        *,
        manual_text: str | None,
        file_bytes: bytes | None,
        media_type: str | None,
        declared_name: str | None,
        aliases: list[dict[str, Any]],
    ) -> list[ExtractedCandidate]:
        if manual_text is None:
            raise ExtractionUnavailable("File extraction requires a configured model provider.")
        text = manual_text.strip()
        if not text:
            raise NoExtractableContent("The update contains no readable text.")
        candidates = []
        seen_versions = set()
        for alias in aliases:
            normalized = alias["alias_text"].strip()
            if not normalized or alias["concept_version_id"] in seen_versions:
                continue
            match = re.search(rf"(?<!\w){re.escape(normalized)}(?!\w)", text, flags=re.IGNORECASE)
            if match is None:
                continue
            seen_versions.add(alias["concept_version_id"])
            candidates.append(
                ExtractedCandidate(
                    candidate_type="concept",
                    payload={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "title": alias["title"][:MAX_CANDIDATE_TITLE_CHARS],
                        "definition": alias.get("definition") or "",
                        "concept_id": str(alias["concept_id"]),
                        "concept_version_id": str(alias["concept_version_id"]),
                        "matched_alias": normalized,
                    },
                    source_locator={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "kind": "text_range",
                        "start": match.start(),
                        "end": match.end(),
                    },
                    confidence=0.9 if alias.get("is_preferred") else 0.8,
                )
            )
            if len(candidates) >= 20:
                break
        for match in FORMULA_PATTERN.finditer(text):
            statement = match.group(0).strip()
            candidates.append(
                ExtractedCandidate(
                    candidate_type="formula",
                    payload={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "title": statement[:MAX_CANDIDATE_TITLE_CHARS],
                        "statement": statement,
                    },
                    source_locator={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "kind": "text_range",
                        "start": match.start(),
                        "end": match.end(),
                    },
                    confidence=0.68,
                )
            )
            if len(candidates) >= 30:
                break
        for match in UNIT_PATTERN.finditer(text):
            statement = match.group(0).strip()
            candidates.append(
                ExtractedCandidate(
                    candidate_type="unit",
                    payload={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "title": statement[:MAX_CANDIDATE_TITLE_CHARS],
                        "statement": statement,
                    },
                    source_locator={
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "kind": "text_range",
                        "start": match.start(),
                        "end": match.end(),
                    },
                    confidence=0.7,
                )
            )
            if len(candidates) >= 40:
                break
        if not candidates:
            raise NoExtractableContent("No approved concept or formula was recognized.")
        return candidates


class OpenRouterExtractionProvider:
    """Bounded OpenRouter chat-completions adapter with structured output."""

    model_key = "openrouter"
    prompt_version = EXTRACTION_PROMPT_VERSION

    def __init__(
        self,
        *,
        api_key: str,
        model: str,
        timeout_seconds: int = 60,
        post_json: Any | None = None,
    ) -> None:
        self.api_key = api_key
        self.model = model
        self.timeout_seconds = timeout_seconds
        self._post_json = post_json or _post_json

    def extract(
        self,
        *,
        manual_text: str | None,
        file_bytes: bytes | None,
        media_type: str | None,
        declared_name: str | None,
        aliases: list[dict[str, Any]],
    ) -> list[ExtractedCandidate]:
        content = [
            {
                "type": "text",
                "text": (
                    "Extract only Physics concepts, formulas, variables and units that are "
                    "explicitly present. Return JSON with a single key `candidates`, a list of "
                    "objects: {candidate_type, payload, source_locator, confidence}. "
                    "candidate_type is one of concept, claim, formula, variable, unit. "
                    "confidence is a number from 0 to 1. Never invent content. Approved aliases: "
                    + ", ".join(alias["alias_text"] for alias in aliases[:60])
                ),
            }
        ]
        if manual_text:
            content.append({"type": "text", "text": manual_text})
        if file_bytes is not None and media_type is not None and declared_name:
            encoded = base64.b64encode(file_bytes).decode("ascii")
            if media_type == "application/pdf":
                content.append(
                    {
                        "type": "file",
                        "file": {
                            "filename": declared_name,
                            "file_data": f"data:application/pdf;base64,{encoded}",
                        },
                    }
                )
            else:
                content.append(
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{media_type};base64,{encoded}"},
                    }
                )
        payload = {
            "model": self.model,
            "temperature": 0,
            "max_tokens": 1200,
            "messages": [
                {"role": "system", "content": "You extract candidate study evidence."},
                {"role": "user", "content": content},
            ],
        }
        try:
            response = self._post_json(
                "https://openrouter.ai/api/v1/chat/completions",
                payload,
                self.api_key,
                self.timeout_seconds,
            )
            raw = response["choices"][0]["message"]["content"]
            parsed = json.loads(raw)
        except (
            KeyError,
            IndexError,
            TypeError,
            json.JSONDecodeError,
            TimeoutError,
            OSError,
        ) as exc:
            raise ExtractionUnavailable(
                "The extraction provider returned an invalid result."
            ) from exc
        candidates = parsed.get("candidates") if isinstance(parsed, dict) else None
        if not isinstance(candidates, list) or not candidates:
            raise NoExtractableContent("The extraction provider found no candidates.")
        result = []
        for item in candidates[:40]:
            if isinstance(item, dict):
                candidate_type = str(item.get("candidate_type", ""))
                payload_value = item.get("payload")
                if candidate_type in CANDIDATE_TYPES:
                    if not isinstance(payload_value, dict) or not payload_value:
                        continue
                    try:
                        confidence = float(item.get("confidence", 0))
                    except (TypeError, ValueError):
                        confidence = 0.0
                    locator = item.get("source_locator")
                    result.append(
                        ExtractedCandidate(
                            candidate_type=candidate_type,
                            payload={**payload_value, "schema_version": CANDIDATE_SCHEMA_VERSION},
                            source_locator=locator
                            if isinstance(locator, dict)
                            else {"kind": "page", "page": 1},
                            confidence=max(0.0, min(1.0, confidence)),
                        )
                    )
        if not result:
            raise NoExtractableContent("The extraction provider returned no usable candidates.")
        return result


def _post_json(
    url: str, payload: dict[str, Any], api_key: str, timeout_seconds: int
) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        method="POST",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            return json.loads(response.read().decode())
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as exc:
        raise ExtractionUnavailable("The extraction provider is unavailable.") from exc


def build_extraction_provider(settings: Any) -> ExtractionProvider:
    if settings.extraction_provider == "openrouter" and settings.openrouter_api_key:
        return OpenRouterExtractionProvider(
            api_key=settings.openrouter_api_key.get_secret_value(),
            model=settings.openrouter_model or "",
            timeout_seconds=settings.openrouter_timeout_seconds,
        )
    return DeterministicExtractionProvider()
