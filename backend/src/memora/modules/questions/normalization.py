"""Bounded, deterministic text normalization for rubric claim matching."""

from __future__ import annotations

import re
import unicodedata
from collections.abc import Iterable

_WHITESPACE = re.compile(r"\s+")
_TYPOGRAPHIC = str.maketrans(
    {
        "\u2018": "'",
        "\u2019": "'",
        "\u201c": '"',
        "\u201d": '"',
        "\u2013": "-",
        "\u2014": "-",
        "\u2212": "-",
    }
)


def normalize_text(value: str) -> str:
    """Normalize Unicode and spacing without importing a locale or model."""

    normalized = unicodedata.normalize("NFKC", value).translate(_TYPOGRAPHIC)
    normalized = normalized.casefold()
    normalized = "".join(
        character
        for character in normalized
        if unicodedata.category(character)[0] != "C" or character == "\n"
    )
    return _WHITESPACE.sub(" ", normalized).strip()


def contains_phrase(haystack: str, needle: str) -> bool:
    """Match a normalized phrase on alphanumeric token boundaries."""

    phrase = needle.strip()
    if not phrase:
        return False
    pattern = r"(?<![0-9a-z])" + re.escape(phrase) + r"(?![0-9a-z])"
    return re.search(pattern, haystack) is not None


def first_matching_phrase(haystack: str, phrases: Iterable[str]) -> str | None:
    """Return the first phrase found, preserving deterministic rubric order."""

    for phrase in phrases:
        if contains_phrase(haystack, phrase):
            return phrase
    return None
