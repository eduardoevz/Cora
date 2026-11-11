"""Exhaustive parameterized TDD tests for DeterministicSafetyInterceptor."""

import time

import pytest
from app.modules.rag_assistant.domain.services.safety_interceptor import (
    DeterministicSafetyInterceptor,
    SafetyTriageCategory,
)


@pytest.mark.parametrize(
    ("query", "expected_category"),
    [
        # 1. HEMORRHAGE_EMERGENCY (with and without accents + colloquial)
        (
            "Estoy empapando una toalla por hora desde hace 3 horas y me siento mareada",
            SafetyTriageCategory.HEMORRHAGE_EMERGENCY,
        ),
        (
            "empapo dos toallas nocturnas cada hora y me salen coagulos gigantes",
            SafetyTriageCategory.HEMORRHAGE_EMERGENCY,
        ),
        (
            "Tengo una hemorragia vaginal muy fuerte y siento que me voy a desmayar",
            SafetyTriageCategory.HEMORRHAGE_EMERGENCY,
        ),
        (
            "cambio el tampon cada 40 minutos porque se rebalsa de sangre y veo borroso",
            SafetyTriageCategory.HEMORRHAGE_EMERGENCY,
        ),
        # 2. ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY
        (
            "Tengo un dolor pelvico subito e insoportable de un solo lado y ganas de vomitar",
            SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY,
        ),
        (
            "Me dio una punzada abdominal desgarradora en el ovario derecho y me desmaye",
            SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY,
        ),
        (
            "Estoy embarazada de 6 semanas, tengo sangrado y un dolor agudo unilateral",
            SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY,
        ),
        (
            "dolor abdominal bajo subito que no me deja ni caminar con sudor frio",
            SafetyTriageCategory.ECTOPIC_OR_ACUTE_PELVIC_EMERGENCY,
        ),
        # 3. OBSTETRIC_PREECLAMPSIA_EMERGENCY
        (
            "Tengo 32 semanas de embarazo, dolor de cabeza muy fuerte y veo lucecitas",
            SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        ),
        (
            "cefalea intensa que no se quita con vision borrosa y manchas negras",
            SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        ),
        (
            "Me tome la presion y salio en 165/112 y me duele mucho la boca del estomago",
            SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        ),
        (
            "tengo escotomas, zumbido de oidos y dolor en el epigastrio estando embarazada",
            SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        ),
        (
            "Se me hincho la cara de repente y tengo la presion en 160/110",
            SafetyTriageCategory.OBSTETRIC_PREECLAMPSIA_EMERGENCY,
        ),
        # 4. FETAL_MOVEMENT_EMERGENCY
        (
            "Mi bebe no se mueve desde ayer en la noche y estoy en la semana 34",
            SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY,
        ),
        (
            "no siento movimientos fetales hoy por mas que tome agua fria",
            SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY,
        ),
        (
            "Siento una disminucion marcada de movimientos de mi bebe todo el dia",
            SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY,
        ),
        (
            "mi bebita dejo de moverse y no da pataditas desde hace muchas horas",
            SafetyTriageCategory.FETAL_MOVEMENT_EMERGENCY,
        ),
        # 5. POSTPARTUM_INFECTION_EMERGENCY
        (
            "Tengo fiebre de 38.8 posparto y los loquios huelen muy mal",
            SafetyTriageCategory.POSTPARTUM_INFECTION_EMERGENCY,
        ),
        (
            "hace 5 dias tuve cesarea, tengo escalofrios, fiebre y flujo con olor fetido",
            SafetyTriageCategory.POSTPARTUM_INFECTION_EMERGENCY,
        ),
        (
            "La herida de la cesarea esta saliendo pus y tengo temperatura de 39 grados",
            SafetyTriageCategory.POSTPARTUM_INFECTION_EMERGENCY,
        ),
        # 6. CARDIORESPIRATORY_THROMBOSIS_EMERGENCY
        (
            "Siento un dolor en el pecho opresivo y me falta el aire de repente",
            SafetyTriageCategory.CARDIORESPIRATORY_THROMBOSIS_EMERGENCY,
        ),
        (
            "No puedo respirar bien, tengo disnea subita y taquicardia en el posparto",
            SafetyTriageCategory.CARDIORESPIRATORY_THROMBOSIS_EMERGENCY,
        ),
        (
            "Tengo una pierna muy hinchada, roja y caliente en la pantorrilla izquierda",
            SafetyTriageCategory.CARDIORESPIRATORY_THROMBOSIS_EMERGENCY,
        ),
        # 7. MENTAL_HEALTH_CRISIS
        (
            "Siento que ya no quiero vivir y todo seria mejor sin mi",
            SafetyTriageCategory.MENTAL_HEALTH_CRISIS,
        ),
        (
            "Tengo pensamientos de hacerme dano o quitarme la vida",
            SafetyTriageCategory.MENTAL_HEALTH_CRISIS,
        ),
        (
            "Me dan miedo mis pensamientos de hacerle dano al bebe o a mi misma",
            SafetyTriageCategory.MENTAL_HEALTH_CRISIS,
        ),
        (
            "no encuentro salida, quiero desaparecer y terminar con mi vida",
            SafetyTriageCategory.MENTAL_HEALTH_CRISIS,
        ),
    ],
)
def test_safety_interceptor_detects_all_red_flags_under_5ms(
    query: str,
    expected_category: SafetyTriageCategory,
) -> None:
    """Verify red flag detection accuracy, empathetic directive, and < 5ms latency."""
    interceptor = DeterministicSafetyInterceptor()

    start = time.perf_counter()
    result = interceptor.evaluate(query_text=query, life_stage="pregnancy")
    elapsed_ms = (time.perf_counter() - start) * 1000.0

    assert elapsed_ms < 5.0
    assert result.is_emergency is True
    assert result.category == expected_category
    assert result.disclaimer_level == "EMERGENCY_URGENT"
    assert len(result.urgent_response_markdown) > 80
    assert len(result.emergency_numbers) >= 1


@pytest.mark.parametrize(
    "benign_query",
    [
        "¿Por qué me duele un poco la cabeza dos días antes de que me baje el periodo?",
        "¿Qué alimentos ricos en calcio recomiendas durante la perimenopausia?",
        "Mi ciclo duró 30 días este mes y 28 el mes pasado, ¿está dentro del rango FIGO?",
        "¿Cómo cambia el moco cervical cuando me acerco a mis días fértiles?",
        "Tengo sofocos moderados en la noche, ¿qué hábitos ayudan a dormir mejor?",
        "¿Cuál es la diferencia entre los loquios rubra y los loquios serosa?",
    ],
)
def test_safety_interceptor_allows_benign_educational_queries(
    benign_query: str,
) -> None:
    """Verify normal clinical questions pass through without false emergency alarms."""
    interceptor = DeterministicSafetyInterceptor()
    result = interceptor.evaluate(query_text=benign_query, life_stage="regular_adult")

    assert result.is_emergency is False
    assert result.category == SafetyTriageCategory.NONE
    assert result.urgent_response_markdown == ""
    assert result.disclaimer_level == "STANDARD"
