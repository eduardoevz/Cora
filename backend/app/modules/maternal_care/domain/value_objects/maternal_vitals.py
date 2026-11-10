from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from app.modules.maternal_care.domain.exceptions.maternal_care_exceptions import (
    InvalidBloodPressureError,
    InvalidGlucoseValueError,
)


@dataclass(frozen=True)
class BloodPressure:
    systolic_mmhg: int
    diastolic_mmhg: int

    def __post_init__(self) -> None:
        if not (60 <= self.systolic_mmhg <= 260):
            raise InvalidBloodPressureError(
                f"Sistólica ({self.systolic_mmhg}) fuera de rango fisiológico "
                "(60-260 mmHg)"
            )
        if not (30 <= self.diastolic_mmhg <= 160):
            raise InvalidBloodPressureError(
                f"Diastólica ({self.diastolic_mmhg}) fuera de rango fisiológico "
                "(30-160 mmHg)"
            )
        if self.systolic_mmhg <= self.diastolic_mmhg:
            raise InvalidBloodPressureError(
                f"Sistólica ({self.systolic_mmhg}) debe ser estrictamente mayor "
                f"que la diastólica ({self.diastolic_mmhg})"
            )

    @property
    def formatted(self) -> str:
        return f"{self.systolic_mmhg}/{self.diastolic_mmhg} mmHg"


class GlucoseTiming(StrEnum):
    FASTING = "fasting"
    POSTPRANDIAL_1H = "postprandial_1h"
    POSTPRANDIAL_2H = "postprandial_2h"
    RANDOM = "random"


@dataclass(frozen=True)
class CapillaryGlucoseReading:
    measured_at: datetime
    value_mg_dl: Decimal
    timing: GlucoseTiming

    def __post_init__(self) -> None:
        if not (Decimal("30.0") <= self.value_mg_dl <= Decimal("600.0")):
            raise InvalidGlucoseValueError(
                f"Valor de glucosa capilar ({self.value_mg_dl} mg/dL) "
                "fuera de límites fisiológicos"
            )


@dataclass(frozen=True)
class MaternalWeightReading:
    measured_at: datetime
    weight_kg: Decimal


class MaternalSymptomType(StrEnum):
    PERSISTENT_SEVERE_HEADACHE = "persistent_severe_headache"
    SCOTOMAS_VISUAL_BLUR = "scotomas_visual_blur"
    EPIGASTRIC_RUQ_PAIN = "epigastric_ruq_pain"
    SUDDEN_FACIAL_HAND_EDEMA = "sudden_facial_hand_edema"
    NAUSEA_VOMITING = "nausea_vomiting"
    DECREASED_FETAL_MOVEMENT = "decreased_fetal_movement"
    VAGINAL_BLEEDING = "vaginal_bleeding"
    AMNIOTIC_FLUID_LEAK = "amniotic_fluid_leak"
    PELVIC_PRESSURE = "pelvic_pressure"


@dataclass(frozen=True)
class MaternalSymptom:
    symptom_type: MaternalSymptomType
    notes: str | None = None


class MaternalAlertSeverity(StrEnum):
    NORMAL = "normal"
    INFO = "info"
    PRIORITY_CONSULT = "priority_consult"
    URGENT_EMERGENCY = "urgent_emergency"


class MaternalRiskCategory(StrEnum):
    PREECLAMPSIA_RISK = "preeclampsia_risk"
    GESTATIONAL_DIABETES_RISK = "gestational_diabetes_risk"
    PRETERM_LABOR_RISK = "preterm_labor_risk"
    FETAL_WELLBEING_RISK = "fetal_wellbeing_risk"
    GENERAL_OBSTETRIC = "general_obstetric"


@dataclass(frozen=True)
class MaternalClinicalAlert:
    severity: MaternalAlertSeverity
    category: MaternalRiskCategory
    title: str
    message: str
    action_recommended: str
