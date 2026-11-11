"""Deterministic semantic Markdown chunker for clinical evidence ingestion."""

import re

from app.modules.education_content.domain.entities import (
    ClinicalArticle,
    ClinicalEvidenceChunk,
    normalize_life_stage,
)


class SemanticMarkdownChunker:
    """Splits clinical Markdown articles by headings and paragraphs with overlap."""

    def __init__(
        self,
        target_words: int = 350,
        max_words: int = 500,
        overlap_words: int = 50,
    ) -> None:
        self._target_words = target_words
        self._max_words = max_words
        self._overlap_words = overlap_words

    def chunk_article(self, article: ClinicalArticle) -> list[ClinicalEvidenceChunk]:
        """Split article body into semantic chunks preserving heading context."""
        sections = self._split_into_sections(article.body_markdown, article.title)
        normalized_stages = [
            normalize_life_stage(s) for s in article.target_life_stages
        ]

        chunks: list[ClinicalEvidenceChunk] = []
        chunk_idx = 0

        for heading, section_text in sections:
            paragraphs = [
                p.strip() for p in re.split(r"\n\s*\n", section_text) if p.strip()
            ]
            if not paragraphs:
                continue

            current_words: list[str] = []
            for para in paragraphs:
                para_words = para.split()
                if (
                    current_words
                    and len(current_words) + len(para_words) > self._target_words
                ):
                    chunk_content = " ".join(current_words)
                    chunks.append(
                        self._build_chunk(
                            article=article,
                            chunk_index=chunk_idx,
                            section_heading=heading,
                            content_text=chunk_content,
                            normalized_stages=normalized_stages,
                        )
                    )
                    chunk_idx += 1
                    overlap = (
                        current_words[-self._overlap_words :]
                        if self._overlap_words > 0
                        else []
                    )
                    current_words = overlap + para_words
                else:
                    current_words.extend(para_words)

                while len(current_words) > self._max_words:
                    slice_words = current_words[: self._target_words]
                    chunks.append(
                        self._build_chunk(
                            article=article,
                            chunk_index=chunk_idx,
                            section_heading=heading,
                            content_text=" ".join(slice_words),
                            normalized_stages=normalized_stages,
                        )
                    )
                    chunk_idx += 1
                    overlap = (
                        slice_words[-self._overlap_words :]
                        if self._overlap_words > 0
                        else []
                    )
                    current_words = overlap + current_words[self._target_words :]

            if current_words:
                chunks.append(
                    self._build_chunk(
                        article=article,
                        chunk_index=chunk_idx,
                        section_heading=heading,
                        content_text=" ".join(current_words),
                        normalized_stages=normalized_stages,
                    )
                )
                chunk_idx += 1

        return chunks

    @staticmethod
    def _split_into_sections(
        markdown_text: str, default_heading: str
    ) -> list[tuple[str, str]]:
        """Group markdown lines under their nearest ## or ### heading."""
        lines = markdown_text.splitlines()
        sections: list[tuple[str, str]] = []
        current_heading = default_heading
        buffer: list[str] = []

        heading_pattern = re.compile(r"^(#{1,3})\s+(.+?)\s*$")
        for line in lines:
            match = heading_pattern.match(line)
            if match:
                if buffer:
                    joined = "\n".join(buffer).strip()
                    if joined:
                        sections.append((current_heading, joined))
                    buffer = []
                current_heading = match.group(2).strip()
            else:
                buffer.append(line)

        if buffer:
            joined = "\n".join(buffer).strip()
            if joined:
                sections.append((current_heading, joined))

        return sections

    @staticmethod
    def _build_chunk(
        article: ClinicalArticle,
        chunk_index: int,
        section_heading: str,
        content_text: str,
        normalized_stages: list[str],
    ) -> ClinicalEvidenceChunk:
        word_count = len(content_text.split())
        estimated_tokens = max(1, int(word_count * 1.3))
        return ClinicalEvidenceChunk(
            article_id=article.id,
            chunk_index=chunk_index,
            section_heading=section_heading,
            content_text=content_text,
            token_count=estimated_tokens,
            target_life_stages=normalized_stages,
            scientific_source=article.scientific_source,
            article_title=article.title,
            article_slug=article.slug,
            source_url=article.source_url,
        )
