import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


def main() -> None:
    root_dir = Path(__file__).resolve().parent.parent.parent
    cred_docx = root_dir / "credenciales" / "credenciales.docx"
    json_name = "cora-5d341-firebase-adminsdk-fbsvc-5851c420a9.json"
    firebase_json = root_dir / "credenciales" / json_name
    backend_dir = root_dir / "backend"

    if not cred_docx.exists():
        print("ERROR: credenciales/credenciales.docx not found.")
        return

    with zipfile.ZipFile(cred_docx) as z:
        xml_content = z.read("word/document.xml")
        root = ET.fromstring(xml_content)
        ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
        paragraphs: list[str] = []
        for elem in root.findall(".//w:p", ns):
            texts = [t.text for t in elem.findall(".//w:t", ns) if t.text]
            if texts:
                paragraphs.append("".join(texts))

    raw_neon = paragraphs[1].strip()
    if raw_neon.startswith("postgresql://"):
        async_neon = raw_neon.replace("postgresql://", "postgresql+asyncpg://", 1)
    else:
        async_neon = raw_neon

    async_neon = async_neon.replace(
        "sslmode=require&channel_binding=require", "ssl=require"
    )

    s3_endpoint = ""
    s3_key_id = ""
    s3_secret = ""
    s3_region = "us-east-2"

    for para_text in paragraphs:
        if "AWS_ENDPOINT_URL_S3=" in para_text:
            s3_endpoint = para_text.split("AWS_ENDPOINT_URL_S3=", 1)[1].strip(" \"'")
        elif "AWS_ACCESS_KEY_ID=" in para_text:
            s3_key_id = para_text.split("AWS_ACCESS_KEY_ID=", 1)[1].strip(" \"'")
        elif "AWS_SECRET_ACCESS_KEY=" in para_text:
            s3_secret = para_text.split("AWS_SECRET_ACCESS_KEY=", 1)[1].strip(" \"'")
        elif "AWS_REGION=" in para_text:
            s3_region = para_text.split("AWS_REGION=", 1)[1].strip(" \"'")

    secrets_dir = backend_dir / "secrets"
    secrets_dir.mkdir(exist_ok=True)

    dst_json = secrets_dir / "firebase_service_account.json"
    if firebase_json.exists():
        dst_json.write_bytes(firebase_json.read_bytes())
        print(f"Copied Firebase service account to {dst_json}")

    env_lines = [
        "# Cora Backend Environment (Live Neon & Firebase)",
        "ENVIRONMENT=development",
        'APP_NAME="Cora Backend"',
        "APP_VERSION=0.1.0",
        "",
        "# Neon PostgreSQL Database",
        f"DATABASE_URL={async_neon}",
        "",
        "# Firebase Auth",
        "FIREBASE_PROJECT_ID=cora-5d341",
        "FIREBASE_CREDENTIALS_PATH=./secrets/firebase_service_account.json",
        "",
        "# Object Storage (S3 / Neon assets)",
        f"R2_ENDPOINT_URL={s3_endpoint}",
        f"R2_ACCESS_KEY_ID={s3_key_id}",
        f"R2_SECRET_ACCESS_KEY={s3_secret}",
        "R2_BUCKET_NAME=assets",
        f"R2_ACCOUNT_ID={s3_region}",
        "",
        "# Gemini AI Defaults",
        "GEMINI_API_KEY=mock-gemini-key",
        "GEMINI_GENERATION_MODEL=gemini-3.8-flash",
        "GEMINI_EMBEDDING_MODEL=gemini-embedding-2",
        "GEMINI_EMBEDDING_DIMENSIONS=768",
        "GEMINI_STORE_INTERACTIONS=false",
    ]

    (backend_dir / ".env").write_text("\n".join(env_lines) + "\n", encoding="utf-8")
    print("Successfully generated backend/.env!")


async def verify_connection() -> None:
    import firebase_admin  # type: ignore[import-untyped]
    from firebase_admin import credentials
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import create_async_engine

    from app.core.config import get_settings

    settings = get_settings()
    masked_url = settings.database_url.split("@")[-1]
    print(f"Verifying database connection to: {masked_url}")
    engine = create_async_engine(settings.database_url)
    async with engine.connect() as conn:
        stmt = text(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'public' ORDER BY table_name;"
        )
        res = await conn.execute(stmt)
        tables = [r[0] for r in res.fetchall()]
        print("Live Neon Database Tables:", tables)
    await engine.dispose()

    print("Verifying Firebase Admin SDK initialization...")
    creds_file = Path(settings.firebase_credentials_path)
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(creds_file))
        firebase_admin.initialize_app(cred, {"projectId": settings.firebase_project_id})
    active_project = str(firebase_admin.get_app().project_id)
    print(f"Firebase Admin SDK initialized for project: {active_project}!")


if __name__ == "__main__":
    import asyncio

    main()
    asyncio.run(verify_connection())
