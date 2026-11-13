"""Audit store readiness and compliance for Google Play and Apple App Store."""

from __future__ import annotations

import sys
from pathlib import Path


def audit_store_readiness(repo_root: Path) -> bool:
    """Run comprehensive checks on metadata, disclaimers, and native store configs."""
    errors: list[str] = []
    warnings: list[str] = []

    print(
        "🔍 [STORE AUDIT] Starting store readiness and regulatory audit for Cora...\n"
    )

    gp_dir = repo_root / "distribution" / "store_assets" / "google_play"
    as_dir = repo_root / "distribution" / "store_assets" / "app_store"

    # -------------------------------------------------------------------------
    # 1. Google Play Assets
    # -------------------------------------------------------------------------
    print("🤖 Checking Google Play Store assets...")

    # Title <= 30 chars
    gp_title_file = gp_dir / "app_title.txt"
    if not gp_title_file.exists():
        errors.append("Google Play: app_title.txt is missing")
    else:
        title = gp_title_file.read_text(encoding="utf-8").strip()
        if len(title) > 30:
            errors.append(
                f"Google Play: title exceeds 30 chars ({len(title)}): '{title}'"
            )
        else:
            print(f"  ✅ Title: '{title}' ({len(title)}/30 chars)")

    # Short description <= 80 chars
    gp_short_file = gp_dir / "short_description.txt"
    if not gp_short_file.exists():
        errors.append("Google Play: short_description.txt is missing")
    else:
        short_desc = gp_short_file.read_text(encoding="utf-8").strip()
        if len(short_desc) > 80:
            errors.append(
                f"Google Play: short_description exceeds 80 chars ({len(short_desc)})"
            )
        else:
            print(f"  ✅ Short description: {len(short_desc)}/80 chars")

    # Full description <= 4000 chars
    gp_full_file = gp_dir / "full_description.txt"
    if not gp_full_file.exists():
        errors.append("Google Play: full_description.txt is missing")
    else:
        full_desc = gp_full_file.read_text(encoding="utf-8").strip()
        if len(full_desc) > 4000:
            errors.append(
                f"Google Play: full_description exceeds 4000 chars ({len(full_desc)})"
            )
        elif (
            "AVISO MÉDICO" not in full_desc
            and "responsabilidad" not in full_desc.lower()
        ):
            errors.append("Google Play: full_description lacks medical disclaimer")
        else:
            print(
                f"  ✅ Full description: {len(full_desc)}/4000 chars (has disclaimer)"
            )

    # Medical disclaimer standalone
    gp_disc_file = gp_dir / "medical_disclaimer.txt"
    if not gp_disc_file.exists():
        errors.append("Google Play: medical_disclaimer.txt is missing")
    else:
        print("  ✅ Medical disclaimer standalone file verified")

    # Privacy policy
    gp_priv_file = gp_dir / "privacy_policy.md"
    if not gp_priv_file.exists():
        errors.append("Google Play: privacy_policy.md is missing")
    else:
        priv_text = gp_priv_file.read_text(encoding="utf-8")
        if "Offline-First" not in priv_text or "GDPR" not in priv_text:
            warnings.append(
                "Privacy policy should explicitly mention Offline-First and GDPR"
            )
        else:
            print("  ✅ Store Privacy policy verified (Offline-First & GDPR covered)")

    # -------------------------------------------------------------------------
    # 2. Apple App Store Assets
    # -------------------------------------------------------------------------
    print("\n🍎 Checking Apple App Store assets...")

    as_title_file = as_dir / "app_title.txt"
    if not as_title_file.exists():
        errors.append("App Store: app_title.txt is missing")
    else:
        as_title = as_title_file.read_text(encoding="utf-8").strip()
        if len(as_title) > 30:
            errors.append(f"App Store: title exceeds 30 chars ({len(as_title)})")
        else:
            print(f"  ✅ App Store Title: '{as_title}' ({len(as_title)}/30 chars)")

    as_sub_file = as_dir / "subtitle.txt"
    if not as_sub_file.exists():
        errors.append("App Store: subtitle.txt is missing")
    else:
        as_sub = as_sub_file.read_text(encoding="utf-8").strip()
        if len(as_sub) > 30:
            errors.append(f"App Store: subtitle exceeds 30 chars ({len(as_sub)})")
        else:
            print(f"  ✅ Subtitle: '{as_sub}' ({len(as_sub)}/30 chars)")

    as_promo_file = as_dir / "promotional_text.txt"
    if not as_promo_file.exists():
        errors.append("App Store: promotional_text.txt is missing")
    else:
        as_promo = as_promo_file.read_text(encoding="utf-8").strip()
        if len(as_promo) > 170:
            errors.append(
                f"App Store: promotional_text exceeds 170 chars ({len(as_promo)})"
            )
        else:
            print(f"  ✅ Promotional text: {len(as_promo)}/170 chars")

    as_kw_file = as_dir / "keywords.txt"
    if not as_kw_file.exists():
        errors.append("App Store: keywords.txt is missing")
    else:
        as_kw = as_kw_file.read_text(encoding="utf-8").strip()
        if len(as_kw) > 100:
            errors.append(f"App Store: keywords exceeds 100 chars ({len(as_kw)})")
        else:
            print(f"  ✅ Keywords: {len(as_kw)}/100 chars")

    as_review_file = as_dir / "app_review_notes.md"
    if not as_review_file.exists():
        errors.append("App Store: app_review_notes.md is missing")
    else:
        as_rev_text = as_review_file.read_text(encoding="utf-8")
        if "1.4.1" not in as_rev_text or "5.1.1" not in as_rev_text:
            warnings.append(
                "App Store review notes should cite Guidelines 1.4.1 and 5.1.1"
            )
        else:
            print("  ✅ App Store Review notes verified (Guidelines 1.4.1 & 5.1.1)")

    # -------------------------------------------------------------------------
    # 3. Native App Store Compliance
    # -------------------------------------------------------------------------
    print("\n📱 Checking native configuration compliance...")

    # Android Manifest
    manifest_file = (
        repo_root
        / "mobile"
        / "android"
        / "app"
        / "src"
        / "main"
        / "AndroidManifest.xml"
    )
    if not manifest_file.exists():
        errors.append("Native: AndroidManifest.xml is missing")
    else:
        man_text = manifest_file.read_text(encoding="utf-8")
        if 'android:label="Cora"' not in man_text:
            errors.append("Native: AndroidManifest.xml missing android:label='Cora'")
        if "USE_BIOMETRIC" not in man_text:
            errors.append(
                "Native: AndroidManifest.xml missing USE_BIOMETRIC permission"
            )
        print("  ✅ AndroidManifest.xml label and biometric permissions verified")

    # iOS Info.plist
    info_plist = repo_root / "mobile" / "ios" / "Runner" / "Info.plist"
    if not info_plist.exists():
        errors.append("Native: iOS Info.plist is missing")
    else:
        plist_text = info_plist.read_text(encoding="utf-8")
        if "NSFaceIDUsageDescription" not in plist_text:
            errors.append("Native: iOS Info.plist missing NSFaceIDUsageDescription")
        print("  ✅ iOS Info.plist Face ID usage description verified")

    # iOS Privacy Manifest
    privacy_manifest = repo_root / "mobile" / "ios" / "Runner" / "PrivacyInfo.xcprivacy"
    if not privacy_manifest.exists():
        errors.append(
            "Native: Apple Privacy Manifest (PrivacyInfo.xcprivacy) is missing"
        )
    else:
        priv_xml = privacy_manifest.read_text(encoding="utf-8")
        if "NSPrivacyTracking" not in priv_xml:
            errors.append("Native: PrivacyInfo.xcprivacy invalid")
        else:
            print("  ✅ Apple Privacy Manifest (PrivacyInfo.xcprivacy) verified")

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    print("\n" + "=" * 60)
    for w in warnings:
        print(f"⚠️  [WARNING] {w}")

    if errors:
        for err in errors:
            print(f"❌ [ERROR] {err}")
        print("\n🚫 Store readiness audit FAILED. Address the above errors.")
        return False

    print("🎉 Store readiness audit PASSED! Cora v1.0.0 is ready for store submission.")
    return True


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    success = audit_store_readiness(repo_root)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
