import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';

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
            // Clinical Info Card
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen Clínico para tu Consulta',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Consolida en 1 a 2 páginas A4 tu historial de ciclo, tratamientos activos, signos vitales y calendario preventivo con formato estandarizado para tu médico.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                            specialistNotes: _notesController.text.trim().isEmpty
                                ? null
                                : _notesController.text.trim(),
                          );
                    },
            ),
            const SizedBox(height: 20),

            // Status Card
            if (exportState == ExportPdfState.completed) ...[
              Card(
                key: const Key('doctor_report_completed_card'),
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Reporte generado con éxito!',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
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
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abriendo diálogo del sistema para compartir PDF...'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (exportState == ExportPdfState.error) ...[
              Card(
                key: const Key('doctor_report_error_card'),
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No fue posible generar el reporte en este momento. Por favor intenta de nuevo.',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
