from collections.abc import Sequence
from datetime import date

from app.modules.identity.domain.value_objects.life_stage import LifeStage
from app.modules.medical_records.domain.models.medical_record_and_vaccine import (
    MedicalExamRecord,
    PreventiveScreeningItem,
)
from app.modules.medical_records.domain.value_objects.record_metadata import (
    ExamType,
    ScreeningUrgency,
)


class PreventiveScreeningCalendarService:
    """Calculates evidence-based clinical preventive screening recommendations

    based on age, life stage, diagnosed conditions, and past medical exams.
    """

    def compute_due_screenings(
        self,
        user_age: int,
        life_stage: LifeStage,
        diagnosed_conditions: Sequence[str] | None = None,
        past_exams: Sequence[MedicalExamRecord] | None = None,
        reference_date: date | None = None,
    ) -> list[PreventiveScreeningItem]:
        today = reference_date or date.today()
        exams = past_exams or []
        items: list[PreventiveScreeningItem] = []

        # Helper to find latest performed exam of given types
        def get_latest_exam(exam_types: set[ExamType]) -> MedicalExamRecord | None:
            matching = [e for e in exams if e.exam_type in exam_types]
            if not matching:
                return None
            return max(matching, key=lambda e: e.performed_at)

        # 1. Adolescence & Young Adulthood Guidelines
        if user_age < 26:
            items.append(
                PreventiveScreeningItem(
                    screening_code="HPV_VACCINE",
                    title="Vacuna contra Virus del Papiloma Humano (VPH)",
                    description=(
                        "Esquema de inmunización para prevención de lesiones "
                        "premalignas y cáncer cervicouterino."
                    ),
                    recommended_age_range="9–26 años",
                    frequency_guideline="Esquema completo de 2 o 3 dosis",
                    urgency=ScreeningUrgency.DUE_NOW,
                )
            )

        # 2. Cervical Cancer Screening (PAP / HPV)
        if 21 <= user_age < 30:
            latest_pap = get_latest_exam({ExamType.PAP_SMEAR})
            is_up_to_date = False
            last_date = None
            if latest_pap:
                last_date = latest_pap.performed_at
                days_since = (today - last_date).days
                if days_since < 365 * 3:
                    is_up_to_date = True

            items.append(
                PreventiveScreeningItem(
                    screening_code="PAP_SMEAR",
                    title="Citología Cervicouterina (Papanicolaou)",
                    description=(
                        "Detección oportuna de alteraciones en células del cuello "
                        "uterino."
                    ),
                    recommended_age_range="21–29 años",
                    frequency_guideline="Cada 3 años si el resultado previo fue normal",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if is_up_to_date
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=last_date,
                )
            )

        elif 30 <= user_age <= 65:
            latest_cervical = get_latest_exam({ExamType.PAP_SMEAR, ExamType.HPV_TEST})
            is_up_to_date = False
            last_date = None
            if latest_cervical:
                last_date = latest_cervical.performed_at
                days_since = (today - last_date).days
                if days_since < 365 * 5:
                    is_up_to_date = True

            items.append(
                PreventiveScreeningItem(
                    screening_code="PAP_OR_HPV",
                    title="Tamizaje Cervical (Co-test PAP + Prueba VPH)",
                    description=(
                        "Prueba molecular de VPH de alto riesgo combinada "
                        "con citología."
                    ),
                    recommended_age_range="30–65 años",
                    frequency_guideline="Cada 5 años (o citología sola cada 3 años)",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if is_up_to_date
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=last_date,
                )
            )

        # 3. Breast Health (Self-awareness, ultrasound, mammography)
        if 20 <= user_age < 40:
            items.append(
                PreventiveScreeningItem(
                    screening_code="BREAST_SELF_AWARENESS",
                    title="Conciencia y Autoexamen Mamario",
                    description=(
                        "Familiarización mensual con el tejido mamario propio "
                        "y consulta ante nódulos o cambios en piel/pezón."
                    ),
                    recommended_age_range="20–39 años",
                    frequency_guideline="Mensual posmenstruación",
                    urgency=ScreeningUrgency.UP_TO_DATE,
                )
            )

        if user_age >= 40:
            latest_mammo = get_latest_exam({ExamType.MAMMOGRAM})
            is_up_to_date = False
            last_date = None
            if latest_mammo:
                last_date = latest_mammo.performed_at
                days_since = (today - last_date).days
                if days_since < 365 * 1.5:  # within ~1.5 years
                    is_up_to_date = True

            items.append(
                PreventiveScreeningItem(
                    screening_code="MAMMOGRAM",
                    title="Mamografía Digital Bilateral",
                    description=(
                        "Estudio radiológico de tamizaje para detección "
                        "temprana de cáncer de mama."
                    ),
                    recommended_age_range="40–74 años",
                    frequency_guideline="Anual o bienal según criterio médico",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if is_up_to_date
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=last_date,
                )
            )

        # 4. Pregnancy-Specific Screenings
        if life_stage == LifeStage.PREGNANCY:
            latest_us = get_latest_exam({ExamType.PRENATAL_ULTRASOUND})
            items.append(
                PreventiveScreeningItem(
                    screening_code="PRENATAL_ULTRASOUND",
                    title="Ecografía Obstétrica de Seguimiento",
                    description=(
                        "Monitoreo ecográfico del crecimiento fetal, "
                        "placenta y anatomía."
                    ),
                    recommended_age_range="Gestación activa",
                    frequency_guideline="Al menos una por trimestre",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if latest_us
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=latest_us.performed_at if latest_us else None,
                )
            )
            items.append(
                PreventiveScreeningItem(
                    screening_code="TDAP_PREGNANCY",
                    title="Vacuna Tdap Materna (Tosferina)",
                    description=(
                        "Inmunización gestacional para transferir anticuerpos "
                        "contra pertussis al recién nacido."
                    ),
                    recommended_age_range="Semanas 27 a 36 de gestación",
                    frequency_guideline="Una dosis en cada embarazo",
                    urgency=ScreeningUrgency.DUE_NOW,
                )
            )
            items.append(
                PreventiveScreeningItem(
                    screening_code="GESTATIONAL_DIABETES_SCREENING",
                    title="Tamizaje de Diabetes Gestacional",
                    description=(
                        "Curva de tolerancia a la glucosa oral de 75g (CTGO)."
                    ),
                    recommended_age_range="Semanas 24 a 28 de gestación",
                    frequency_guideline="Prueba diagnóstica en segundo trimestre",
                    urgency=ScreeningUrgency.DUE_NOW,
                )
            )

        # 5. Cardiometabolic Health
        if user_age >= 45 or life_stage in (
            LifeStage.PERIMENOPAUSE,
            LifeStage.SENIOR_VITALITY,
        ):
            latest_blood = get_latest_exam({ExamType.BLOOD_PANEL})
            is_up_to_date = False
            last_date = None
            if latest_blood:
                last_date = latest_blood.performed_at
                days_since = (today - last_date).days
                if days_since < 365:
                    is_up_to_date = True

            items.append(
                PreventiveScreeningItem(
                    screening_code="CARDIOMETABOLIC_PANEL",
                    title="Perfil Lipídico y Glucosa en Ayuno",
                    description=(
                        "Monitoreo de riesgo cardiovascular: colesterol total, "
                        "HDL, LDL, triglicéridos y glicemia."
                    ),
                    recommended_age_range=">= 45 años o en transición hormonal",
                    frequency_guideline="Anual",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if is_up_to_date
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=last_date,
                )
            )

        # 6. Bone Health / Osteoporosis
        if user_age >= 65 or (
            user_age >= 50 and life_stage == LifeStage.SENIOR_VITALITY
        ):
            latest_dexa = get_latest_exam({ExamType.BONE_DENSITOMETRY_DEXA})
            is_up_to_date = False
            last_date = None
            if latest_dexa:
                last_date = latest_dexa.performed_at
                days_since = (today - last_date).days
                if days_since < 365 * 2:
                    is_up_to_date = True

            items.append(
                PreventiveScreeningItem(
                    screening_code="BONE_DENSITOMETRY_DEXA",
                    title="Densitometría Ósea (DEXA Cadera y Columna)",
                    description=(
                        "Evaluación diagnóstica de masa mineral ósea para "
                        "prevención de osteopenia y fracturas."
                    ),
                    recommended_age_range=(
                        ">= 65 años (o posmenopausia con factores de riesgo)"
                    ),
                    frequency_guideline="Cada 2 años",
                    urgency=ScreeningUrgency.UP_TO_DATE
                    if is_up_to_date
                    else ScreeningUrgency.DUE_NOW,
                    last_performed_at=last_date,
                )
            )

        # 7. Shingles (Herpes Zoster Vaccine)
        if user_age >= 50:
            items.append(
                PreventiveScreeningItem(
                    screening_code="SHINGLES_VACCINE",
                    title="Vacuna contra Herpes Zóster",
                    description=(
                        "Prevención de reactivación de varicela-zóster y "
                        "neuralgia posherpética."
                    ),
                    recommended_age_range=">= 50 años",
                    frequency_guideline="Esquema recombinante de 2 dosis",
                    urgency=ScreeningUrgency.DUE_NOW,
                )
            )

        return items
