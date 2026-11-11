from dataclasses import dataclass
from typing import Protocol
from uuid import UUID


@dataclass(frozen=True)
class PresignedUploadUrlResponse:
    upload_url: str
    storage_key: str
    expires_in_seconds: int
    required_headers: dict[str, str]


class IFileStorage(Protocol):
    """Port for secure object storage operations (Cloudflare R2 / S3 compatible)."""

    async def create_presigned_upload_url(
        self,
        user_id: UUID,
        record_id: UUID,
        file_name: str,
        mime_type: str,
        max_size_bytes: int = 15 * 1024 * 1024,
        expires_in_seconds: int = 900,
    ) -> PresignedUploadUrlResponse: ...

    async def create_presigned_download_url(
        self,
        user_id: UUID,
        storage_key: str,
        expires_in_seconds: int = 900,
    ) -> str: ...

    async def delete_user_prefix(self, user_id: UUID) -> None: ...
