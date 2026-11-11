import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/records/domain/models/specialist_entry.dart';
import 'package:mobile/features/records/domain/models/vaccination_record.dart';
import 'package:mobile/features/records/presentation/providers/medical_records_providers.dart';
import 'package:uuid/uuid.dart';

class VaccinationsAndSpecialistsPage extends ConsumerStatefulWidget {
  const VaccinationsAndSpecialistsPage({super.key});

  @override
  ConsumerState<VaccinationsAndSpecialistsPage> createState() =>
      _VaccinationsAndSpecialistsPageState();
}

class _VaccinationsAndSpecialistsPageState
    extends ConsumerState<VaccinationsAndSpecialistsPage> {
  final _uuid = const Uuid();

  Future<void> _showAddVaccinationDialog(
      BuildContext context, String userId) async {
    VaccineType selectedType = VaccineType.influenza;
    int doseNumber = 1;
    final clinicController = TextEditingController();
    final notesController = TextEditingController();

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
                    'Registrar Vacuna',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<VaccineType>(
                    key: const Key('vaccine_type_dropdown'),
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Vacuna',
                      border: OutlineInputBorder(),
                    ),
                    items: VaccineType.values.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text(v.displayName),
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
                    key: const Key('dose_number_field'),
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de Dosis',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      doseNumber = int.tryParse(val) ?? 1;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('vaccine_clinic_field'),
                    controller: clinicController,
                    decoration: const InputDecoration(
                      labelText: 'Clínica o Centro de Salud',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('save_vaccination_button'),
                    onPressed: () async {
                      final record = VaccinationRecord(
                        id: _uuid.v4(),
                        userId: userId,
                        vaccineType: selectedType,
                        doseNumber: doseNumber,
                        administeredAt: DateTime.now(),
                        administratorClinic:
                            clinicController.text.trim().isEmpty
                                ? null
                                : clinicController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await ref
                          .read(medicalRecordsRepositoryProvider)
                          .saveVaccination(record);
                      ref.invalidate(vaccinationsProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Guardar Registro de Vacuna'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddSpecialistDialog(
      BuildContext context, String userId) async {
    final nameController = TextEditingController();
    SpecialtyType selectedSpecialty = SpecialtyType.gynecology;
    final clinicController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

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
                    'Agregar Especialista',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('specialist_name_field'),
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo del Médico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SpecialtyType>(
                    key: const Key('specialty_type_dropdown'),
                    initialValue: selectedSpecialty,
                    decoration: const InputDecoration(
                      labelText: 'Especialidad',
                      border: OutlineInputBorder(),
                    ),
                    items: SpecialtyType.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedSpecialty = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('specialist_clinic_field'),
                    controller: clinicController,
                    decoration: const InputDecoration(
                      labelText: 'Hospital o Clínica',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('specialist_phone_field'),
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de Contacto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('save_specialist_button'),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final specialist = SpecialistEntry(
                        id: _uuid.v4(),
                        userId: userId,
                        fullName: nameController.text.trim(),
                        specialty: selectedSpecialty,
                        clinicName: clinicController.text.trim().isEmpty
                            ? null
                            : clinicController.text.trim(),
                        phoneNumber: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                        isFavorite: true,
                        createdAt: DateTime.now(),
                      );
                      await ref
                          .read(medicalRecordsRepositoryProvider)
                          .saveSpecialist(specialist);
                      ref.invalidate(specialistsProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Guardar Especialista'),
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
    final user = ref.watch(activeUserProfileProvider);
    final userId = user?.id ?? 'default-user';
    final theme = Theme.of(context);

    final vaccinationsAsync = ref.watch(vaccinationsProvider);
    final specialistsAsync = ref.watch(specialistsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vacunas y Directorio Médico'),
          bottom: const TabBar(
            tabs: [
              Tab(
                key: Key('vaccinations_tab'),
                icon: Icon(Icons.vaccines_outlined),
                text: 'Cartilla de Vacunación',
              ),
              Tab(
                key: Key('specialists_tab'),
                icon: Icon(Icons.people_outline),
                text: 'Especialistas',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Vacunación
            vaccinationsAsync.when(
              data: (vaccines) {
                if (vaccines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vaccines,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay vacunas registradas aún.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Registrar Primera Vacuna'),
                          onPressed: () =>
                              _showAddVaccinationDialog(context, userId),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vaccines.length,
                  itemBuilder: (context, index) {
                    final vax = vaccines[index];
                    return Card(
                      key: Key('vaccination_card_$index'),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.shield_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          vax.vaccineType.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Dosis #${vax.doseNumber} • ${vax.administeredAt.toLocal().toString().split(' ').first}'
                          '${vax.administratorClinic != null ? ' • ${vax.administratorClinic}' : ''}',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error al cargar vacunas: $e')),
            ),

            // Tab 2: Especialistas
            specialistsAsync.when(
              data: (specialists) {
                if (specialists.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_outlined,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Directorio de especialistas vacío.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Agregar Especialista'),
                          onPressed: () =>
                              _showAddSpecialistDialog(context, userId),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: specialists.length,
                  itemBuilder: (context, index) {
                    final spec = specialists[index];
                    return Card(
                      key: Key('specialist_card_$index'),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.local_hospital_outlined,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                spec.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (spec.isFavorite)
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${spec.specialty.displayName}'
                          '${spec.clinicName != null ? ' • ${spec.clinicName}' : ''}'
                          '${spec.phoneNumber != null ? '\nTel: ${spec.phoneNumber}' : ''}',
                        ),
                        trailing: spec.phoneNumber != null
                            ? IconButton(
                                icon: const Icon(Icons.phone),
                                color: theme.colorScheme.primary,
                                tooltip: 'Llamar al médico',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Marcando a ${spec.fullName}: ${spec.phoneNumber}'),
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Error al cargar especialistas: $e')),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            return FloatingActionButton(
              key: const Key('add_record_fab'),
              child: const Icon(Icons.add),
              onPressed: () {
                final tabController = DefaultTabController.of(ctx);
                if (tabController.index == 0) {
                  _showAddVaccinationDialog(context, userId);
                } else {
                  _showAddSpecialistDialog(context, userId);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
