"""Domain entity for designated family or emergency support contact."""

from dataclasses import dataclass, field
from uuid import UUID, uuid4

from app.modules.mature_health.domain.exceptions.mature_health_exceptions import (
    InvalidSupportContactError,
)


@dataclass
class TrustedSupportContact:
    """Primary trusted family member, caregiver, or support contact for senior user."""

    contact_name: str
    relationship: str
    phone_number: str
    notes: str | None = None
    is_primary: bool = True
    id: UUID = field(default_factory=uuid4)
    user_id: UUID | None = None

    def __post_init__(self) -> None:
        if not self.contact_name or not self.contact_name.strip():
            raise InvalidSupportContactError("contact_name cannot be empty")
        if not self.phone_number or not self.phone_number.strip():
            raise InvalidSupportContactError("phone_number cannot be empty")
        self.contact_name = self.contact_name.strip()
        self.phone_number = self.phone_number.strip()
