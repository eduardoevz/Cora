import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PostpartumAlertItem(BaseModel):
    severity: str = Field(
        ...,
        description=("urgent_emergency | high_priority_consult | routine_observation"),
    )
    category: str = Field(
        ...,
        description="hemorrhage | endometritis | wound | pelvic_floor",
    )
    title: str
    message: str
    action_recommended: str


class RecordPostpartumRecoveryRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    days_postpartum: int = Field(
        ..., ge=0, le=365, description="Días transcurridos desde el parto"
    )
    lochia_stage: str = Field(
        ...,
        description="rubra | serosa | alba | none",
    )
    lochia_flow: str = Field(
        ...,
        description="none | light | moderate | heavy | severe_hemorrhage",
    )
    foul_odor: bool = Field(
        default=False,
        description="Olor fétido o sospecha de infección puerperal",
    )
    maternal_temperature_c: float | None = Field(
        default=None,
        ge=34.0,
        le=43.0,
        description="Temperatura axilar/timpánica materna en °C",
    )
    perineal_wound_status: str | None = Field(
        default=None,
        description=(
            "healing_well | mild_pain | severe_pain | erythema_edema | "
            "purulent_discharge | wound_dehiscence | not_applicable"
        ),
    )
    cesarean_wound_status: str | None = Field(
        default=None,
        description=(
            "intact_clean | erythema_induration | fluid_discharge | "
            "severe_pain | gaping_dehiscence | not_applicable"
        ),
    )
    pelvic_floor_symptoms: list[str] = Field(
        default_factory=list,
        description=(
            "normal | urinary_incontinence | fecal_incontinence | "
            "pelvic_heaviness_prolapse | dyspareunia"
        ),
    )
    notes: str | None = Field(default=None, max_length=500)


class PostpartumRecoveryResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    logged_at: datetime | None = None
    days_postpartum: int
    lochia_stage: str
    lochia_flow: str
    foul_odor: bool
    maternal_temperature_c: float | None = None
    perineal_wound_status: str | None = None
    cesarean_wound_status: str | None = None
    pelvic_floor_symptoms: list[str] = Field(default_factory=list)
    notes: str | None = None
    alerts: list[PostpartumAlertItem] = Field(default_factory=list)


class LogLactationSessionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    started_at: datetime = Field(..., description="Inicio de la toma o extracción")
    ended_at: datetime = Field(..., description="Fin de la toma o extracción")
    left_duration_seconds: int = Field(
        default=0, ge=0, description="Segundos al pecho izquierdo"
    )
    right_duration_seconds: int = Field(
        default=0, ge=0, description="Segundos al pecho derecho"
    )
    last_offered_breast: str = Field(
        default="none",
        description="left | right | both | none",
    )
    bottle_volume_ml: float | None = Field(
        default=None, ge=0.0, description="Volumen suministrado en biberón (ml)"
    )
    feeding_type: str = Field(
        default="breast_only",
        description="breast_only | bottle_expressed | bottle_formula | mixed",
    )
    notes: str | None = Field(default=None, max_length=500)


class LactationSessionResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    started_at: datetime
    ended_at: datetime
    left_duration_seconds: int
    right_duration_seconds: int
    total_duration_seconds: int
    last_offered_breast: str
    suggested_next_breast: str
    bottle_volume_ml: float | None = None
    feeding_type: str
    notes: str | None = None


class AddMilkStashRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    pumped_at: datetime = Field(
        ..., description="Fecha y hora de extracción de leche materna"
    )
    volume_ml: float = Field(..., gt=0.0, description="Volumen extraído en mililitros")
    storage_location: str = Field(
        default="refrigerator",
        description="room_temp | refrigerator | freezer | deep_freezer",
    )
    notes: str | None = Field(default=None, max_length=500)


class MilkStashResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    pumped_at: datetime
    volume_ml: float
    storage_location: str
    expires_at: datetime
    is_consumed: bool
    consumed_at: datetime | None = None
    notes: str | None = None


class EpdsQuestionnaireResponses(BaseModel):
    model_config = ConfigDict(extra="forbid")

    item_1: int = Field(..., ge=0, le=3, description="Capacidad de reír (0-3)")
    item_2: int = Field(
        ..., ge=0, le=3, description="Mirar con agrado hacia el futuro (0-3)"
    )
    item_3: int = Field(
        ..., ge=0, le=3, description="Culpabilidad innecesaria (0-3, invertido)"
    )
    item_4: int = Field(..., ge=0, le=3, description="Ansiedad sin causa (0-3)")
    item_5: int = Field(
        ..., ge=0, le=3, description="Miedo o pánico sin motivo (0-3, invertido)"
    )
    item_6: int = Field(
        ..., ge=0, le=3, description="Cosas que me sobrepasan (0-3, invertido)"
    )
    item_7: int = Field(
        ..., ge=0, le=3, description="Dificultad para dormir (0-3, invertido)"
    )
    item_8: int = Field(
        ..., ge=0, le=3, description="Tristeza o desdicha (0-3, invertido)"
    )
    item_9: int = Field(
        ..., ge=0, le=3, description="Llanto descontrolado (0-3, invertido)"
    )
    item_10: int = Field(
        ..., ge=0, le=3, description="Pensamiento de autolesión (0-3, invertido)"
    )


class EvaluateEpdsRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    days_postpartum: int = Field(
        ..., ge=0, le=365, description="Días transcurridos desde el parto"
    )
    responses: EpdsQuestionnaireResponses


class EpdsScreeningResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    screened_at: datetime | None = None
    days_postpartum: int
    responses: dict[str, int]
    total_score: int
    item_10_score: int
    self_harm_risk: bool
    severity: str
    clinical_summary: str
    action_recommended: str
