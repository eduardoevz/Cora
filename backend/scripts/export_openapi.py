#!/usr/bin/env python3
"""Export the FastAPI OpenAPI schema to a deterministic contracts/openapi.json file."""

import json
import sys
from pathlib import Path

# Ensure backend root is in sys.path
backend_root = Path(__file__).resolve().parents[1]
if str(backend_root) not in sys.path:
    sys.path.insert(0, str(backend_root))

from app.main import create_app  # noqa: E402


def export_openapi() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    contracts_dir = repo_root / "contracts"
    contracts_dir.mkdir(parents=True, exist_ok=True)

    contract_file = contracts_dir / "openapi.json"

    app = create_app()
    schema = app.openapi()

    formatted_json = json.dumps(schema, indent=2, sort_keys=True) + "\n"
    contract_file.write_text(formatted_json, encoding="utf-8")

    print(f"Successfully exported OpenAPI contract to: {contract_file}")


if __name__ == "__main__":
    export_openapi()
