from app.core.errors import DomainError


class ClinicalTrackingError(DomainError):
    """Base exception for clinical tracking domain errors."""


class InvalidWellnessMetricError(ClinicalTrackingError):
    """Raised when a daily wellness metric violates physiological boundaries."""

    def __init__(self, metric_name: str, value: object, valid_range: str) -> None:
        super().__init__(
            code="invalid_wellness_metric",
            title="Métrica de Bienestar Fuera de Rango",
            detail=(
                f"{metric_name} inválido: {value}. "
                f"El rango fisiológico permitido es {valid_range}."
            ),
            status_code=400,
        )


class InvalidBasalTemperatureError(ClinicalTrackingError):
    """Raised when a basal body temperature is outside physiological limits."""

    def __init__(self, value: object) -> None:
        super().__init__(
            code="invalid_basal_temperature",
            title="Temperatura Basal Fuera de Rango Fisiológico",
            detail=(
                f"Temperatura basal inválida: {value} °C. "
                "El rango fisiológico humano permitido es 35.00 °C – 42.00 °C."
            ),
            status_code=400,
        )
