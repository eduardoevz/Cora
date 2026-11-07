---
trigger: always_on
description: TDD biomedico obligatorio (Red-Green-Refactor), seguridad clinica, lenguaje ubicuo DDD y privacidad de datos de salud (PHI).
---

# Regla 03 — TDD Biomédico, Seguridad Clínica y Empatía

## 1. TDD Estricto en Lógica Clínica (`Red → Green → Refactor`)

La salud femenina no admite heurísticas improvisadas ni cálculos sin respaldo clínico. Antes de implementar cualquier algoritmo en `domain/`, **es obligatorio escribir primero las pruebas unitarias parametrizadas que fallen**:

1. **Salud Cíclica y Ginecológica (FIGO / SOP / Adolescencia):**
   - Criterios FIGO de sangrado uterino anormal: frecuencia normal (`24–38` días), polimenorrea (`< 24` días), oligomenorrea (`> 38` días), duración prolongada (`> 8` días) y sangrado intermenstrual.
   - Ajuste obligatorio de umbrales cuando la usuaria está en etapa `ADOLESCENCE` (ciclos fisiológicamente variables de `21–45` días en primeros años posmenarquia) o tiene diagnóstico base de **SOP**, **Endometriosis** o método hormonal activo, evitando falsas alarmas.
2. **Fertilidad y Concepción:**
   - Validación fisiológica de `BasalBodyTemperature` (`35.0 °C – 42.0 °C`), detección de salto térmico bifásico sostenido (`>= 3` mediciones posovulatorias superiores a las `6` previas) combinado con pico de LH y moco cervical fértil.
3. **Obstetricia y Posparto (ACOG / OMS / EPDS):**
   - `BloodPressure`: invariante `systolic > diastolic`, alerta preventiva ante hipertensión gestacional (`>= 140/90 mmHg`) y bandera roja inmediata de preeclampsia severa (`>= 160/110 mmHg` o `>= 140/90 mmHg` acompañada de cefalea intensa, escotomas/alteraciones visuales o epigastralgia).
   - **Escala de Edimburgo (EPDS):** cálculo exacto de los 10 ítems (`0–30` puntos), activando alerta de apoyo prioritario ante puntaje de corte clínico (`>= 10–13`) y **activación inmediata e incondicional de línea de crisis/urgencias si el ítem 10 (pensamientos de autolesión) es `> 0`**, independientemente del puntaje total.
4. **Transición Hormonal y Plenitud (STRAW+10):**
   - Clasificación de variabilidad menstrual persistente (`>= 7` días de diferencia entre ciclos consecutivos en perimenopausia temprana, amenorrea `>= 60` días en tardía, `12` meses para menopausia establecida).

## 2. Triaje Determinista Obligatorio (`DeterministicSafetyInterceptor`)

- Ninguna consulta libre en el chat de Cora llega al LLM sin atravesar primero `DeterministicSafetyInterceptor`.
- Si se detectan banderas rojas (hemorragia aguda que empapa `>= 1` toalla/hora por `2+` horas, dolor pélvico súbito incapacitante, signos de preeclampsia/eclampsia, disminución marcada de movimientos fetales, fiebre puerperal con loquios fétidos, dolor torácico/disnea o ideación autolesiva), el sistema **corta la ejecución hacia el LLM** y devuelve en milisegundos una respuesta estructurada de derivación médica urgente.

## 3. Lenguaje Ubicuo y Tono Comunicacional

- **En el código fuente y base de datos:** Inglés técnico clínico exacto (`MenstrualCycle`, `FollicularPhase`, `LutealPhase`, `BasalBodyTemperature`, `BloodPressure`, `LochiaRecord`, `HotFlashEpisode`, `LifeStage`).
- **En textos orientados a la usuaria (UI, PDFs, notificaciones y prompts RAG):** Español empático, claro, respetuoso y **nunca alarmista ni determinista**. Cora **orienta, educa y detecta patrones preventivos**; nunca emite diagnósticos médicos definitivos y siempre acompaña las alertas con la recomendación de consultar a su profesional de salud.

## 4. Privacidad de Datos Sensibles (PHI / PII)

- Jamás registrar (`logger.info`/`error`) payloads clínicos crudos, síntomas íntimos, notas libres, resultados de EPDS ni tokens JWT en texto plano. Los logs de observabilidad solo pueden contener `request_id`, `user_id` pseudonimizado/UUID, módulo y código de estado.
