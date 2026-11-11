"""Unit tests for PII-free UserClinicalMemoryAssembler and cycle correlations."""

from app.modules.rag_assistant.domain.services.clinical_memory_assembler import (
    CycleDaySymptomPoint,
    RawUserClinicalSnapshot,
    UserClinicalMemoryAssembler,
)


def test_clinical_memory_assembler_excludes_all_pii_and_detects_correlations() -> None:
    """Verify assembled memory strips PII and detects recurrent cycle-day symptoms."""
    snapshot = RawUserClinicalSnapshot(
        first_name="Valeria",
        last_name="Montes de Oca",
        email="valeria.montes@secret-email.com",
        birth_year=1994,
        current_life_stage="regular_adult",
        diagnosed_conditions=["sop"],
        hormonal_method="none",
        recent_cycle_lengths=[28, 29, 28],
        current_cycle_day=27,
        current_cycle_phase="luteal",
        symptom_points=[
            CycleDaySymptomPoint(cycle_index=1, cycle_day=26, symptom="cefalea"),
            CycleDaySymptomPoint(cycle_index=2, cycle_day=27, symptom="cefalea"),
            CycleDaySymptomPoint(cycle_index=3, cycle_day=28, symptom="cefalea"),
            CycleDaySymptomPoint(
                cycle_index=1, cycle_day=14, symptom="moco_clara_huevo"
            ),
        ],
        active_treatments=["Inositol 2000mg cada 24h"],
        stage_specific_notes="Ciclos ovulatorios regulares en los últimos 3 meses.",
    )

    assembler = UserClinicalMemoryAssembler(reference_year=2026)
    memory = assembler.assemble(snapshot)
    prompt_block = memory.to_prompt_block()

    # 1. Zero PII invariant
    assert "Valeria" not in prompt_block
    assert "Montes" not in prompt_block
    assert "valeria.montes" not in prompt_block
    assert "secret-email.com" not in prompt_block

    # 2. Clinical context & deterministic correlation detection
    assert "regular_adult" in prompt_block
    assert "32 años" in prompt_block
    assert any("cefalea" in corr.lower() for corr in memory.detected_correlations)
    assert any("26" in corr and "28" in corr for corr in memory.detected_correlations)
    assert "Inositol 2000mg" in prompt_block
