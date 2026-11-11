from typing import Protocol

from app.modules.medical_records.application.dtos.doctor_report_dtos import (
    DoctorReportData,
)


class IClinicalReportRenderer(Protocol):
    """Port for rendering concise Doctor-Ready clinical reports."""

    async def render_doctor_ready_pdf(self, report_data: DoctorReportData) -> bytes: ...
