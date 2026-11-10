from dataclasses import dataclass
from enum import StrEnum


class LochiaStage(StrEnum):
    RUBRA = "rubra"
    SEROSA = "serosa"
    ALBA = "alba"


class LochiaFlow(StrEnum):
    LIGHT = "light"
    MODERATE = "moderate"
    HEAVY_SOAKING_PAD_UNDER_1H = "heavy_soaking_pad_under_1h"
    CLOTS_GREATER_THAN_GOLF_BALL = "clots_greater_than_golf_ball"


class PerinealWoundStatus(StrEnum):
    HEALING_NORMALLY = "healing_normally"
    MILD_PAIN = "mild_pain"
    ERYTHEMA_EDEMA = "erythema_edema"
    PURULENT_DISCHARGE_OR_DEHISCENCE = "purulent_discharge_or_dehiscence"


class CesareanWoundStatus(StrEnum):
    HEALING_NORMALLY = "healing_normally"
    MILD_PAIN = "mild_pain"
    ERYTHEMA_HEAT = "erythema_heat"
    PURULENT_DRAINAGE_OR_DEHISCENCE = "purulent_drainage_or_dehiscence"


class PelvicFloorSymptom(StrEnum):
    NORMAL = "normal"
    STRESS_INCONTINENCE = "stress_incontinence"
    URGENCY_INCONTINENCE = "urgency_incontinence"
    PELVIC_HEAVINESS_PROLAPSE = "pelvic_heaviness_prolapse"
    PAIN_OR_DYSPAREUNIA = "pain_or_dyspareunia"


class PostpartumAlertSeverity(StrEnum):
    REASSURING = "reassuring"
    ROUTINE_MONITORING = "routine_monitoring"
    PRIORITY_CONSULT = "priority_consult"
    URGENT_EMERGENCY = "urgent_emergency"
    IMMEDIATE_CRISIS_SUPPORT = "immediate_crisis_support"


@dataclass(frozen=True)
class PostpartumClinicalAlert:
    severity: PostpartumAlertSeverity
    category: str
    title: str
    message: str
    action_recommended: str
