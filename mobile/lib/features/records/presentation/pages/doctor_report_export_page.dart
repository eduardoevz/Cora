import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DoctorReportExportPage extends ConsumerStatefulWidget {
  const DoctorReportExportPage({super.key});

  @override
  ConsumerState<DoctorReportExportPage> createState() =>
      _DoctorReportExportPageState();
}

class _DoctorReportExportPageState
    extends ConsumerState<DoctorReportExportPage> {
  int _selectedWindowMonths = 6;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exportState = ref.watch(doctorReportExportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Doctor-Ready PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CoraStitchPageHeader(
              eyebrow: 'HISTORIA CLÍNICA PORTÁTIL',
              title: 'Reporte Doctor-Ready',
              eyebrowIcon: Icons.picture_as_pdf_outlined,
            ),
            const SizedBox(height: 10),
            // Clinical Info Card
            const CoraInfoCallout(
              title: 'Resumen Clínico para tu Consulta',
              subtitle:
                  'Consolida en 1 a 2 páginas A4 tu historial de ciclo, tratamientos activos, signos vitales y calendario preventivo con formato estandarizado para tu médico.',
              icon: Icons.medical_information_outlined,
              phaseKey: 'follicular',
            ),
            const SizedBox(height: 20),

            // Window Selection
            Text(
              'Ventana de Tiempo a Incluir',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              key: const Key('doctor_report_window_selector'),
              segments: const [
                ButtonSegment(
                  value: 3,
                  label: Text('3 Meses'),
                ),
                ButtonSegment(
                  value: 6,
                  label: Text('6 Meses'),
                ),
                ButtonSegment(
                  value: 12,
                  label: Text('12 Meses'),
                ),
              ],
              selected: {_selectedWindowMonths},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedWindowMonths = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // Specialist Notes
            Text(
              'Motivo de Consulta o Notas para el Médico (Opcional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('doctor_report_notes_input'),
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Ej. Control ginecológico anual, revisión de dolor pélvico o cambio de anticonceptivo...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),

            // Export Button
            ElevatedButton.icon(
              key: const Key('doctor_report_generate_button'),
              icon: exportState == ExportPdfState.generating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                exportState == ExportPdfState.generating
                    ? 'Generando PDF Clínico...'
                    : 'Generar Reporte Doctor-Ready (PDF)',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: exportState == ExportPdfState.generating
                  ? null
                  : () async {
                      await ref
                          .read(doctorReportExportProvider.notifier)
                          .generateReport(
                            reportingWindowMonths: _selectedWindowMonths,
                            specialistNotes:
                                _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                          );
                    },
            ),
            const SizedBox(height: 20),
            CoraSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'PREVISUALIZACIÓN DE HOJA CLÍNICA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      CoraMintStatusPill(
                        label: 'Formato A4',
                        variant: CoraStatusPillVariant.softMint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CoraBiometricTrendChart(
                    values: const [28, 29, 28, 30, 28],
                    lineColor: CoraTheme.tokensOf(context).primaryDeep,
                    height: 64,
                    startLabel: 'Inicio',
                    endLabel: 'Actual',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CoraBlushInsetBox(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          'Ventana: $_selectedWindowMonths m',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      CoraBlushInsetBox(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          'Estándar FIGO/ACOG',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Card
            if (exportState == ExportPdfState.completed) ...[
              CoraSurfaceCard(
                key: const Key('doctor_report_completed_card'),
                backgroundColor: CoraTheme.tokensOf(context).follicularSurface,
                borderColor: CoraTheme.tokensOf(context)
                    .follicular
                    .withValues(alpha: 0.4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: CoraTheme.tokensOf(context).follicular,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '¡Reporte generado con éxito!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Documento A4 listo con tipografía médica y formato Doctor-Ready.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('doctor_report_share_button'),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir o Guardar PDF'),
                      onPressed: () async {
                        final bytes = ref
                            .read(doctorReportExportProvider.notifier)
                            .lastGeneratedPdfBytes;
                        final messenger = ScaffoldMessenger.of(context);
                        if (bytes == null || bytes.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Primero genera el reporte PDF.'),
                            ),
                          );
                          return;
                        }
                        try {
                          final dir = await getApplicationDocumentsDirectory();
                          final fileName =
                              'cora_reporte_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          final file = File(p.join(dir.path, fileName));
                          await file.writeAsBytes(bytes, flush: true);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('PDF guardado en: ${file.path}'),
                            ),
                          );
                        } catch (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Reporte PDF listo en memoria para compartir.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ] else if (exportState == ExportPdfState.error) ...[
              const CoraAlertBanner(
                key: Key('doctor_report_error_card'),
                title: 'No fue posible generar el reporte',
                description:
                    'No fue posible generar el reporte en este momento. Por favor intenta de nuevo.',
                isUrgent: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
