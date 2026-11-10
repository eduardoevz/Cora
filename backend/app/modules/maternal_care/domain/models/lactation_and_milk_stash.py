from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import StrEnum
from uuid import uuid4


class StorageLocation(StrEnum):
    ROOM_TEMP = "room_temp"
    REFRIGERATOR = "refrigerator"
    FREEZER = "freezer"


class FeedingType(StrEnum):
    BREAST_ONLY = "breast_only"
    BOTTLE_EXPRESSED = "bottle_expressed"
    BOTTLE_FORMULA = "bottle_formula"
    MIXED = "mixed"


class OfferedBreast(StrEnum):
    LEFT = "left"
    RIGHT = "right"
    BOTH = "both"


@dataclass(frozen=True)
class LactationSession:
    id: str
    user_id: str
    started_at: datetime
    ended_at: datetime
    left_duration_seconds: int = 0
    right_duration_seconds: int = 0
    last_offered_breast: OfferedBreast = OfferedBreast.LEFT
    bottle_volume_ml: float | None = None
    feeding_type: FeedingType = FeedingType.BREAST_ONLY
    notes: str | None = None

    @property
    def total_duration_seconds(self) -> int:
        return self.left_duration_seconds + self.right_duration_seconds

    @property
    def suggested_next_breast(self) -> OfferedBreast:
        if self.last_offered_breast == OfferedBreast.RIGHT:
            return OfferedBreast.LEFT
        elif self.last_offered_breast == OfferedBreast.LEFT:
            return OfferedBreast.RIGHT
        return OfferedBreast.LEFT


@dataclass(frozen=True)
class MilkStashEntry:
    id: str
    user_id: str
    pumped_at: datetime
    volume_ml: float
    storage_location: StorageLocation
    expires_at: datetime
    is_consumed: bool = False
    consumed_at: datetime | None = None
    notes: str | None = None

    @classmethod
    def calculate_expiration(
        cls, pumped_at: datetime, location: StorageLocation
    ) -> datetime:
        if location == StorageLocation.ROOM_TEMP:
            return pumped_at + timedelta(hours=4)
        elif location == StorageLocation.REFRIGERATOR:
            return pumped_at + timedelta(days=4)
        elif location == StorageLocation.FREEZER:
            return pumped_at + timedelta(days=180)
        return pumped_at + timedelta(hours=4)

    @classmethod
    def create(
        cls,
        user_id: str,
        pumped_at: datetime,
        volume_ml: float,
        storage_location: StorageLocation,
        id: str | None = None,
        notes: str | None = None,
    ) -> "MilkStashEntry":
        entry_id = id or str(uuid4())
        expires = cls.calculate_expiration(pumped_at, storage_location)
        return cls(
            id=entry_id,
            user_id=user_id,
            pumped_at=pumped_at,
            volume_ml=volume_ml,
            storage_location=storage_location,
            expires_at=expires,
            is_consumed=False,
            consumed_at=None,
            notes=notes,
        )
