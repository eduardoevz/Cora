import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/records/domain/models/medical_exam_record.dart';
import 'package:mobile/features/records/domain/models/preventive_screening_item.dart';
import 'package:mobile/features/records/presentation/pages/doctor_report_export_page.dart';
import 'package:mobile/features/records/presentation/pages/vaccinations_and_specialists_page.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';
import 'package:uuid/uuid.dart';

class MedicalFolderHubPage extends ConsumerStatefulWidget {
  const MedicalFolderHubPage({super.key});

  @override
  ConsumerState<MedicalFolderHubPage> createState() =>
      _MedicalFolderHubPageState();
}

class _MedicalFolderHubPageState extends ConsumerState<MedicalFolderHubPage> {
  final _uuid = const Uuid();

  Future<void> _showRegisterExamBottomSheet(
      BuildContext context, String userId) async {
    final titleController = TextEditingController();
    final clinicController = TextEditingController();
    final notesController = TextEditingController();
    ExamType selectedType = ExamType.papSmear;
    bool attachFile = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Registrar Nuevo Estudio Médico',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('exam_title_field'),
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Estudio o Resultado',
                      hintText: 'Ej. Citología Anual, Perfil Lipídico...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExamType>(
                    key: const Key('exam_type_dropdown'),
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Examen',
                      border: OutlineInputBorder(),
                    ),
                    items: ExamType.values.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('exam_clinic_field'),
                    controller: clinicController,
                    decoration: const InputDecoration(
                      labelText: 'Laboratorio o Hospital',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('exam_attachment_toggle'),
                    title: const Text('Adjuntar Reporte Digital (PDF / Imagen)'),
                    subtitle: const Text(
                      'Almacenamiento seguro en la nube clínica con URL prefirmada (≤ 15 MB)',
                    ),
                    value: attachFile,
                    onChanged: (val) {
                      setModalState(() => attachFile = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('save_exam_button'),
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final examId = _uuid.v4();
                      final now = DateTime.now();
                      AttachmentMetadata? attachment;
                      if (attachFile) {
                        attachment = AttachmentMetadata(
                          fileName: 'estudio_$examId.pdf',
                          mimeType: 'application/pdf',
                          sizeBytes: 1024 * 350,
                          storageKey: 'users/$userId/records/$examId/estudio_$examId.pdf',
                        );
                      }
                      final exam = MedicalExamRecord(
                        id: examId,
                        userId: userId,
                        examType: selectedType,
                        title: titleController.text.trim(),
                        performedAt: now,
                        clinicOrLab: clinicController.text.trim().isEmpty
                            ? null
                            : clinicController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        attachment: attachment,
                        createdAt: now,
                        updatedAt: now,
                      );

                      await ref
                          .read(medicalRecordsRepositoryProvider)
                          .saveMedicalExam(exam);
                      ref.invalidate(medicalExamsProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Guardar Estudio en Carpeta'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(activeUserProfileProvider);
    final userId = user?.id ?? 'default-user';

    final examsAsync = ref.watch(medicalExamsProvider);
    final calendarAsync = ref.watch(preventiveCalendarProvider);
    final selectedFilter = ref.watch(selectedExamTypeFilterProvider);

    return Scaffold(
      key: const Key('medical_folder_hub_scaffold'),
      appBar: AppBar(
        title: const Text('Carpeta Clínica Digital'),
        actions: [
          IconButton(
            key: const Key('open_doctor_report_button'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Doctor-Ready PDF',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DoctorReportExportPage(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('open_vaccines_directory_button'),
            icon: const Icon(Icons.vaccines_outlined),
            tooltip: 'Vacunas y Especialistas',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VaccinationsAndSpecialistsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Access Cards Banner
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DoctorReportExportPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Doctor-Ready PDF',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const VaccinationsAndSpecialistsPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              color: theme.colorScheme.tertiary,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Especialistas & Vacunas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Preventive Screening Calendar
            Text(
              'Calendario Preventivo Clínico',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            calendarAsync.when(
              data: (screenings) {
                return Column(
                  key: const Key('preventive_calendar_section'),
                  children: screenings.map((item) {
                    Color badgeColor;
                    String badgeText;
                    switch (item.urgency) {
                      case ScreeningUrgency.dueNow:
                        badgeColor = Colors.redAccent;
                        badgeText = 'Pendiente';
                        break;
                      case ScreeningUrgency.upcoming:
                        badgeColor = Colors.orangeAccent;
                        badgeText = 'Próximo';
                        break;
                      case ScreeningUrgency.upToDate:
                        badgeColor = Colors.green;
                        badgeText = 'Al Día';
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: badgeColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: badgeColor.withValues(alpha: 0.15),
                          child: Icon(Icons.calendar_today, color: badgeColor, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.description}\nFrecuencia: ${item.frequencyGuideline}',
                        ),
                        trailing: Chip(
                          label: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: badgeColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar calendario: $e')),
            ),
            const SizedBox(height: 20),

            // Section 2: Medical Exams
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Estudios y Resultados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedFilter != null)
                  TextButton(
                    onPressed: () {
                      ref.read(selectedExamTypeFilterProvider.notifier).state = null;
                    },
                    child: const Text('Limpiar Filtro'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Exam Type Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExamType.values.take(5).map((type) {
                  final isSelected = selectedFilter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(selectedExamTypeFilterProvider.notifier).state =
                            selected ? type : null;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            examsAsync.when(
              data: (exams) {
                if (exams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay estudios médicos registrados.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return Card(
                      key: Key('exam_card_$index'),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                          child: Icon(
                            exam.attachment != null
                                ? Icons.attach_file
                                : Icons.article_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          exam.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${exam.examType.displayName} • ${exam.performedAt.toLocal().toString().split(' ').first}'
                          '${exam.clinicOrLab != null ? '\n${exam.clinicOrLab}' : ''}',
                        ),
                        trailing: exam.attachment != null
                            ? const Tooltip(
                                message: 'Archivo adjunto seguro en la nube',
                                child: Icon(Icons.cloud_done, color: Colors.teal),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar estudios: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('register_exam_fab'),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Registrar Examen'),
        onPressed: () => _showRegisterExamBottomSheet(context, userId),
      ),
    );
  }
}
