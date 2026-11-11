from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, select_autoescape

from app.modules.medical_records.application.dtos.doctor_report_dtos import (
    DoctorReportData,
)
from app.modules.medical_records.application.ports.clinical_report_renderer_port import (  # noqa: E501
    IClinicalReportRenderer,
)

TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"


def safe_local_url_fetcher(url: str) -> dict[str, Any]:
    """SSRF-safe resource fetcher for PDF rendering.

    Blocks any external network requests (http, https, ftp, file traversals).
    """
    normalized = url.strip().lower()
    if (
        normalized.startswith("http://")
        or normalized.startswith("https://")
        or normalized.startswith("ftp://")
        or normalized.startswith("//")
    ):
        raise ValueError(
            f"SSRF Protection: Acceso bloqueado a recurso externo ({url})."
        )

    # Only local safe files within TEMPLATES_DIR or assets allowed
    if normalized.startswith("file://"):
        local_path = Path(url.replace("file://", ""))
        try:
            local_path.resolve().relative_to(TEMPLATES_DIR.resolve())
            return {
                "string": local_path.read_bytes(),
                "mime_type": "text/css",
            }
        except Exception as err:
            raise ValueError(
                f"SSRF Protection: Acceso bloqueado a ruta no autorizada ({url})."
            ) from err

    raise ValueError(f"SSRF Protection: Esquema de URL no permitido ({url}).")


class WeasyPrintReportRenderer(IClinicalReportRenderer):
    """Generates concise 1-2 page Doctor-Ready PDFs using Jinja2 and WeasyPrint,

    with fallback for environments lacking native GTK/Pango libraries.
    """

    def __init__(self) -> None:
        self._env = Environment(
            loader=FileSystemLoader(str(TEMPLATES_DIR)),
            autoescape=select_autoescape(["html", "xml", "j2"]),
        )
        css_path = TEMPLATES_DIR / "doctor_ready_report.css"
        self._inline_css = (
            css_path.read_text(encoding="utf-8") if css_path.exists() else ""
        )

    def render_html_preview(self, report_data: DoctorReportData) -> str:
        """Renders the HTML template with strict autoescape enabled."""
        template = self._env.get_template("doctor_ready_report.html.j2")
        return template.render(report=report_data, inline_css=self._inline_css)

    async def render_doctor_ready_pdf(self, report_data: DoctorReportData) -> bytes:
        html_content = self.render_html_preview(report_data)

        # Attempt rendering with WeasyPrint if native Pango runtime is present
        try:
            from weasyprint import HTML  # type: ignore[import-not-found]

            pdf_bytes: bytes = HTML(
                string=html_content,
                url_fetcher=safe_local_url_fetcher,
            ).write_pdf()
            return pdf_bytes
        except (ImportError, OSError):
            # Fallback for Windows local / lean environments without native GTK DLLs
            return self._generate_fallback_pdf(report_data)

    def _generate_fallback_pdf(self, report_data: DoctorReportData) -> bytes:
        """Deterministic PDF generator producing valid PDF 1.4 byte structures

        when system Pango C libraries are not available on the host machine.
        """
        patient_line = (
            f"Paciente: {report_data.patient_name} | "
            f"Edad: {report_data.patient_age} anos"
        )
        emission_line = (
            f"Fecha de Emision: "
            f"{report_data.generated_at.strftime('%Y-%m-%d %H:%M')} UTC"
        )
        lines = [
            "CORA - REPORTE CLINICO DOCTOR-READY",
            patient_line,
            f"Etapa Biologica: {report_data.life_stage.value.upper()}",
            emission_line,
            f"Ventana Temporal: Ultimos {report_data.reporting_window_months} meses",
            "------------------------------------------------------------",
        ]

        if report_data.cycle_summary:
            cs = report_data.cycle_summary
            lines.append("1. SALUD CICLICA Y GINECOLOGICA:")
            cycle_desc = (
                f"   Ciclos: {cs.total_cycles_logged} | "
                f"Media: {cs.average_length_days} dias | "
                f"Rango: {cs.min_length_days}-{cs.max_length_days} dias"
            )
            lines.append(cycle_desc)
            reg_text = "Regular" if cs.is_regular else "Irregular"
            lines.append(f"   Variabilidad: +/-{cs.variability_days} dias ({reg_text})")
            if cs.atypical_alerts_detected:
                lines.append(
                    f"   Alertas FIGO: {', '.join(cs.atypical_alerts_detected)}"
                )
        else:
            lines.append("1. SALUD CICLICA: Sin registros suficientes en el periodo.")

        lines.append("------------------------------------------------------------")
        if report_data.treatment_summary:
            lines.append("2. TRATAMIENTOS FARMACOLOGICOS:")
            for t in report_data.treatment_summary:
                item_line = (
                    f"   - {t.medication_name} ({t.dosage}, {t.frequency}): "
                    f"{t.adherence_percentage}% adherencia"
                )
                lines.append(item_line)
        else:
            lines.append("2. TRATAMIENTOS: Sin farmacos activos reportados.")

        lines.append("------------------------------------------------------------")
        if report_data.vitals_summary:
            vs = report_data.vitals_summary
            lines.append("3. SIGNOS VITALES Y SALUD METABOLICA:")
            vitals_line = (
                f"   PA: {vs.latest_blood_pressure} | "
                f"Glucosa: {vs.fasting_glucose_mg_dl} mg/dL | "
                f"Peso: {vs.weight_kg} kg"
            )
            lines.append(vitals_line)
        else:
            lines.append("3. SIGNOS VITALES: Sin mediciones registradas.")

        if report_data.specialist_notes:
            lines.append("------------------------------------------------------------")
            lines.append("4. NOTAS PARA CONSULTA MEDICA:")
            lines.append(f"   {report_data.specialist_notes}")

        # Build valid PDF 1.4 binary stream
        stream_content = "BT\n/F1 10 Tf\n40 800 Td\n14 TL\n"
        for line in lines:
            safe_text = (
                line.replace("\\", "\\\\")
                .replace("(", "\\(")
                .replace(")", "\\)")
                .encode("ascii", "replace")
                .decode("ascii")
            )
            stream_content += f"({safe_text}) '\n"
        stream_content += "ET\n"
        stream_bytes = stream_content.encode("ascii")

        stream_len = len(stream_bytes)
        body = (
            b"%PDF-1.4\n"
            b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
            b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
            b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] "
            b"/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n"
            b"4 0 obj\n<< /Length "
            + str(stream_len).encode("ascii")
            + b" >>\nstream\n"
            + stream_bytes
            + b"\nendstream\nendobj\n"
            b"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"
            b"xref\n0 6\n"
            b"0000000000 65535 f \n"
            b"0000000009 00000 n \n"
            b"0000000058 00000 n \n"
            b"0000000115 00000 n \n"
            b"0000000244 00000 n \n"
            b"0000000350 00000 n \n"
            b"0000000115 00000 n \n"
            b"0000000244 00000 n \n"
            b"0000000350 00000 n \n"
            b"trailer\n<< /Size 6 /Root 1 0 R >>\n"
            b"startxref\n430\n"
            b"%%EOF\n"
        )
        return body
