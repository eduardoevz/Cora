"""create education content and pgvector hnsw tables

Revision ID: 0010
Revises: 0009
Create Date: 2026-11-10 21:15:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from pgvector.sqlalchemy import Vector
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0010"
down_revision: str | None = "0009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. Enable pgvector extension in PostgreSQL
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    # 2. Create clinical_articles table
    op.create_table(
        "clinical_articles",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column("slug", sa.String(160), nullable=False, unique=True, index=True),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("body_markdown", sa.Text(), nullable=False),
        sa.Column(
            "target_life_stages",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
        ),
        sa.Column(
            "clinical_tags",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
        ),
        sa.Column("scientific_source", sa.String(255), nullable=False),
        sa.Column("source_url", sa.String(500), nullable=False),
        sa.Column("reviewed_by", sa.String(200), nullable=False),
        sa.Column("reading_time_minutes", sa.Integer(), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 3. Create clinical_evidence_chunks table with vector(768)
    op.create_table(
        "clinical_evidence_chunks",
        sa.Column("id", sa.Uuid(as_uuid=True), primary_key=True),
        sa.Column(
            "article_id",
            sa.Uuid(as_uuid=True),
            sa.ForeignKey("clinical_articles.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("chunk_index", sa.Integer(), nullable=False),
        sa.Column("section_heading", sa.String(255), nullable=False),
        sa.Column("content_text", sa.Text(), nullable=False),
        sa.Column("token_count", sa.Integer(), nullable=False),
        sa.Column(
            "target_life_stages",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
        ),
        sa.Column("scientific_source", sa.String(255), nullable=False),
        sa.Column("embedding", Vector(768), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_clinical_evidence_chunks_article_idx",
        "clinical_evidence_chunks",
        ["article_id", "chunk_index"],
    )

    # 4. Create HNSW cosine similarity index on clinical_evidence_chunks.embedding
    op.execute(
        "CREATE INDEX ix_clinical_evidence_chunks_embedding_hnsw "
        "ON clinical_evidence_chunks "
        "USING hnsw (embedding vector_cosine_ops) "
        "WITH (m = 16, ef_construction = 64)"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_clinical_evidence_chunks_embedding_hnsw")
    op.drop_index(
        "ix_clinical_evidence_chunks_article_idx",
        table_name="clinical_evidence_chunks",
    )
    op.drop_table("clinical_evidence_chunks")
    op.drop_table("clinical_articles")
