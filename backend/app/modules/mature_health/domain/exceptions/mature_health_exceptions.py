"""Domain exceptions for mature health (menopause and senior vitality)."""


class MatureHealthDomainError(Exception):
    """Base exception for all domain errors in mature health module."""


class InvalidHotFlashEpisodeError(MatureHealthDomainError):
    """Raised when hot flash intensity or attributes are invalid."""


class InvalidCardiometabolicReadingError(MatureHealthDomainError):
    """Raised when cardiometabolic parameters are unphysiological."""


class InvalidBoneDensityReadingError(MatureHealthDomainError):
    """Raised when DXA T-score or BMD values violate physiological bounds."""


class InvalidFallAssessmentError(MatureHealthDomainError):
    """Raised when fall risk assessment contains negative or invalid metrics."""


class InvalidSupportContactError(MatureHealthDomainError):
    """Raised when trusted support contact name or phone number is invalid."""


class InvalidPelvicLogError(MatureHealthDomainError):
    """Raised when urogynecology or continence record values are invalid."""
