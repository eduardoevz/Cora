# App Store Review Notes & Compliance Information — Cora

**Application Name:** Cora: Salud Femenina Integral  
**Bundle Identifier:** `com.cora.health.mobile`  
**Primary Category:** Health & Fitness  
**Secondary Category:** Medical / Lifestyle  

---

## 1. Demo Credentials & Test Instructions

Cora is an **Offline-First** application. The reviewer can test the full user journey without requiring network connectivity or third-party authentication:

* **Instant Guest/Offline Access:** On the launch screen, tap *"Comenzar sin cuenta"* (Start Offline) to immediately access the full 3-layer onboarding and select any of the 7 life stages.
* **Test Account (Optional for Sync):**
  * **Email:** `apple.reviewer@cora.health`
  * **Password:** `ReviewerCora2026!`
  * **SMS/2FA:** Not required for test accounts.

---

## 2. Medical & Clinical Compliance (App Store Guideline 1.4.1)

* **Not a Medical Device:** Cora is designed exclusively for health monitoring, cycle tracking, maternal wellness logging, and preventive education. It does **not** provide clinical diagnoses, does **not** prescribe pharmaceuticals, and explicitly includes disclaimers across all screens and reports.
* **Clinical Basis:** All algorithms follow published, peer-reviewed international guidelines:
  * Menstrual regularity & patterns: **FIGO** guidelines.
  * Pregnancy alerts: **ACOG** thresholds (gestational hypertension >= 140/90 mmHg).
  * Menopausal transition: **STRAW+10** criteria.
  * Postpartum mental health: **EPDS** (Edinburgh Postnatal Depression Scale) with automatic emergency crisis referral when item 10 > 0.
* **Emergency Referral:** If any severe red flag is detected (e.g. suspected preeclampsia or self-harm thoughts), Cora immediately halts automated responses and displays direct emergency hospital contact recommendations.

---

## 3. Data Privacy & App Privacy Manifest (App Store Guideline 5.1.1)

* **Zero Tracking:** Cora does **not** track users across third-party apps or websites (`NSPrivacyTracking = false`).
* **Apple Privacy Manifest:** `mobile/ios/Runner/PrivacyInfo.xcprivacy` is included in the application bundle, declaring only standard local file access (`NSPrivacyAccessedAPICategoryUserDefaults`, `NSPrivacyAccessedAPICategoryFileTimestamp`).
* **Biometric Authentication:** Face ID (`NSFaceIDUsageDescription`) is used exclusively for the on-device "Modo Discreto" (Discreet Mode) to lock intimate health records from unauthorized physical access.

---

## 4. Key Features for Review Verification

1. **Life-Stage Switcher:** Tap the stage selector on the Home Dashboard to switch between Adolescence, Regular Adult, Conception, Pregnancy, Postpartum, Perimenopause, and Senior Vitality.
2. **Discreet Mode:** Navigate to Settings -> Modo Discreto to enable biometric protection or mask the app icon.
3. **Doctor-Ready PDF Export:** Navigate to Medical Records -> Exportar Reporte Clínico to generate an on-device longitudinal summary.
4. **GDPR Account Purge:** Navigate to Settings -> Privacidad y Datos -> Eliminar Cuenta to verify irreversible on-device data deletion.
