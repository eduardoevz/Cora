"""Gemini Embedding 2 adapter (768 dimensions) using official google-genai SDK."""

import hashlib
import math
from typing import Any

from google import genai
from google.genai import types


class GeminiEmbeddingAdapter:
    """Generates 768-dimensional semantic vectors using gemini-embedding-2."""

    def __init__(
        self,
        client: Any | None = None,
        api_key: str | None = None,
        model_name: str = "gemini-embedding-2",
        dimensions: int = 768,
    ) -> None:
        self._model_name = model_name
        self._dimensions = dimensions
        if client is not None:
            self._client = client
        elif api_key and not api_key.startswith("mock-"):
            self._client = genai.Client(api_key=api_key)
        else:
            self._client = None

    def embed_text(self, text: str) -> list[float]:
        """Generate a 768-dimensional vector for a single text string."""
        if self._client is None:
            return self._deterministic_vector(text)

        response = self._client.models.embed_content(
            model=self._model_name,
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=self._dimensions),
        )
        embeddings = getattr(response, "embeddings", None)
        if embeddings and len(embeddings) > 0:
            values = getattr(embeddings[0], "values", None)
            if values:
                return [float(x) for x in values]
        return self._deterministic_vector(text)

    def embed_batch(self, texts: list[str]) -> list[list[float]]:
        """Generate 768-dimensional vectors for a list of strings."""
        if not texts:
            return []
        if self._client is None:
            return [self._deterministic_vector(t) for t in texts]

        response = self._client.models.embed_content(
            model=self._model_name,
            contents=texts,
            config=types.EmbedContentConfig(output_dimensionality=self._dimensions),
        )
        embeddings = getattr(response, "embeddings", None)
        if embeddings and len(embeddings) == len(texts):
            return [
                [float(x) for x in getattr(emb, "values", [])] for emb in embeddings
            ]
        return [self._deterministic_vector(t) for t in texts]

    def _deterministic_vector(self, text: str) -> list[float]:
        """Generate a unit-norm 768-dim lexical-hash vector for offline/test mode."""
        vec = [0.0] * self._dimensions
        tokens = [
            tok.strip(".,;:¿?¡!()\"'").lower()
            for tok in text.split()
            if len(tok.strip(".,;:¿?¡!()\"'")) >= 3
        ]
        if not tokens:
            tokens = ["cora"]
        for tok in tokens:
            digest = hashlib.sha256(tok.encode("utf-8")).digest()
            for idx in range(0, 16, 2):
                bucket = ((digest[idx] << 8) | digest[idx + 1]) % self._dimensions
                sign = 1.0 if (digest[idx] & 1) == 0 else -1.0
                vec[bucket] += sign
        norm = math.sqrt(sum(v * v for v in vec)) or 1.0
        return [round(v / norm, 6) for v in vec]
