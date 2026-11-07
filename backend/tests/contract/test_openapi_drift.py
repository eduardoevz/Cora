import json
from pathlib import Path

from app.main import create_app


def test_runtime_openapi_matches_committed_contract() -> None:
    """Ensure the committed contracts/openapi.json is strictly in sync with the
    live FastAPI OpenAPI schema.
    """
    repo_root = Path(__file__).resolve().parents[3]
    contract_file = repo_root / "contracts" / "openapi.json"

    assert contract_file.exists(), (
        f"Contract file not found at {contract_file}. "
        "Run scripts/export_openapi.py to generate it."
    )

    app = create_app()
    runtime_schema = app.openapi()

    committed_schema = json.loads(contract_file.read_text(encoding="utf-8"))

    runtime_formatted = json.dumps(runtime_schema, indent=2, sort_keys=True)
    committed_formatted = json.dumps(committed_schema, indent=2, sort_keys=True)

    assert runtime_formatted == committed_formatted, (
        "OpenAPI schema drift detected! Run scripts/export_openapi.py and review diff."
    )
