from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


class ProblemDetails(BaseModel):
    """RFC 7807 Problem Details for HTTP APIs payload model."""

    type: str = Field(
        ...,
        description="URI reference that identifies the problem type.",
    )
    title: str = Field(
        ...,
        description="Short, human-readable summary of the problem type.",
    )
    status: int = Field(
        ...,
        description="HTTP status code applicable to this problem.",
    )
    detail: str = Field(
        ...,
        description="Human-readable explanation specific to this occurrence.",
    )
    code: str = Field(
        ...,
        description="Machine-readable application specific error code.",
    )
    instance: str | None = Field(
        default=None,
        description="URI reference identifying the specific occurrence.",
    )


class DomainError(Exception):
    """Base domain exception for pure clinical and business logic errors."""

    def __init__(
        self,
        code: str,
        title: str,
        detail: str,
        status_code: int = 400,
        instance: str | None = None,
    ) -> None:
        super().__init__(detail)
        self.code = code
        self.title = title
        self.detail = detail
        self.status_code = status_code
        self.instance = instance

    def to_problem_details(self) -> ProblemDetails:
        return ProblemDetails(
            type=f"urn:cora:error:{self.code}",
            title=self.title,
            status=self.status_code,
            detail=self.detail,
            code=self.code,
            instance=self.instance,
        )


class EntityNotFoundError(DomainError):
    """Raised when an expected domain entity cannot be found."""

    def __init__(self, entity: str, identifier: str) -> None:
        super().__init__(
            code="entity_not_found",
            title="Recurso No Encontrado",
            detail=f"{entity} con identificador '{identifier}' no fue encontrado.",
            status_code=404,
        )


class ConflictError(DomainError):
    """Raised when an operation conflicts with existing domain state."""

    def __init__(self, entity: str, detail: str) -> None:
        super().__init__(
            code="conflict_error",
            title="Conflicto de Estado",
            detail=detail,
            status_code=409,
        )


async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    """Handle domain errors and serialize as RFC 7807 problem details."""
    problem = exc.to_problem_details()
    if problem.instance is None:
        problem.instance = request.url.path

    return JSONResponse(
        status_code=exc.status_code,
        content=problem.model_dump(exclude_none=True),
        media_type="application/problem+json",
    )


async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Handle request validation errors with RFC 7807 format."""
    details = "; ".join(
        f"{'.'.join(str(loc) for loc in err['loc'])}: {err['msg']}"
        for err in exc.errors()
    )
    problem = ProblemDetails(
        type="urn:cora:error:validation_error",
        title="Request Validation Error",
        status=422,
        detail=details,
        code="validation_error",
        instance=request.url.path,
    )
    return JSONResponse(
        status_code=422,
        content=problem.model_dump(exclude_none=True),
        media_type="application/problem+json",
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Handle standard HTTP exceptions with RFC 7807 format."""
    detail_str = (
        str(exc.detail) if isinstance(exc.detail, (str, dict, list)) else "Error"
    )
    problem = ProblemDetails(
        type=f"urn:cora:error:http_{exc.status_code}",
        title="HTTP Error",
        status=exc.status_code,
        detail=detail_str,
        code=f"http_{exc.status_code}",
        instance=request.url.path,
    )
    return JSONResponse(
        status_code=exc.status_code,
        content=problem.model_dump(exclude_none=True),
        media_type="application/problem+json",
        headers=exc.headers,
    )


def register_error_handlers(app: FastAPI) -> None:
    """Register all global RFC 7807 exception handlers on the FastAPI app."""
    app.add_exception_handler(DomainError, domain_error_handler)  # type: ignore[arg-type]
    app.add_exception_handler(
        RequestValidationError,
        validation_error_handler,  # type: ignore[arg-type]
    )
    app.add_exception_handler(HTTPException, http_exception_handler)  # type: ignore[arg-type]
