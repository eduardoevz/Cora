import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:mobile/features/pregnancy/presentation/providers/pregnancy_providers.dart';
import 'package:uuid/uuid.dart';

class BirthPlanAndAppointmentsPage extends ConsumerStatefulWidget {
  final PregnancyEpisodeEntity episode;

  const BirthPlanAndAppointmentsPage({
    super.key,
    required this.episode,
  });

  @override
  ConsumerState<BirthPlanAndAppointmentsPage> createState() =>
      _BirthPlanAndAppointmentsPageState();
}

class _BirthPlanAndAppointmentsPageState
    extends ConsumerState<BirthPlanAndAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Birth Plan State
  final Set<String> _selectedCompanions = {};
  final Set<String> _selectedPainManagement = {};
  final Set<String> _selectedEnvironment = {};
  final Set<String> _selectedPostpartum = {};
  final TextEditingController _specialRequestsController =
      TextEditingController();
  bool _birthPlanLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _populateBirthPlan(BirthPlanEntity? plan) {
    if (plan != null && !_birthPlanLoaded) {
      _selectedCompanions.addAll(plan.companionPreferences);
      _selectedPainManagement.addAll(plan.painManagement);
      _selectedEnvironment.addAll(plan.deliveryEnvironment);
      _selectedPostpartum.addAll(plan.immediatePostpartum);
      if (plan.specialRequests != null) {
        _specialRequestsController.text = plan.specialRequests!;
      }
      _birthPlanLoaded = true;
    }
  }

  Future<void> _saveBirthPlan() async {
    final user = ref.read(activeUserProfileProvider);
    final userId = user?.id ?? 'current_user';

    final plan = BirthPlanEntity(
      companionPreferences: _selectedCompanions.toList(),
      painManagement: _selectedPainManagement.toList(),
      deliveryEnvironment: _selectedEnvironment.toList(),
      immediatePostpartum: _selectedPostpartum.toList(),
      specialRequests: _specialRequestsController.text.trim().isEmpty
          ? null
          : _specialRequestsController.text.trim(),
    );

    final repo = ref.read(pregnancyRepositoryProvider);
    await repo.saveBirthPlan(widget.episode.id, userId, plan);
    ref.invalidate(birthPlanProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan de parto guardado correctamente.'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _showAddAppointmentDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final clinicController = TextEditingController();
    final topicsController = TextEditingController();
    final notesController = TextEditingController();
    int week = 20;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programar Cita Prenatal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: clinicController,
                      decoration: const InputDecoration(
                        labelText: 'Profesional de salud o Clínica',
                        prefixIcon: Icon(Icons.local_hospital),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                    const Duration(days: 30)),
                                lastDate: DateTime.now().add(
                                    const Duration(days: 300)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setModalState(() => selectedTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Semana Gestacional: ',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        DropdownButton<int>(
                          value: week,
                          items: List.generate(39, (i) => i + 4).map((w) {
                            return DropdownMenuItem(
                              value: w,
                              child: Text('Semana $w'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => week = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: topicsController,
                      decoration: const InputDecoration(
                        labelText: 'Preguntas / Temas para la consulta (separar por coma)',
                        prefixIcon: Icon(Icons.question_answer),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas adicionales o indicaciones',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Cita Prenatal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (clinicController.text.trim().isEmpty) {
                            return;
                          }
                          final scheduledAt = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final topics = topicsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();

                          final appointment = PrenatalAppointmentEntity(
                            id: const Uuid().v4(),
                            pregnancyEpisodeId: widget.episode.id,
                            scheduledAt: scheduledAt,
                            doctorOrClinic: clinicController.text.trim(),
                            gestationalWeek: week,
                            topicsToDiscuss: topics,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            isCompleted: false,
                          );

                          final user =
                              ref.read(activeUserProfileProvider);
                          final userId = user?.id ?? 'current_user';

                          await ref
                              .read(pregnancyRepositoryProvider)
                              .saveAppointment(appointment, userId);
                          ref.invalidate(prenatalAppointmentsProvider);

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingPlanAsync = ref.watch(birthPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Parto y Citas'),
        backgroundColor: Colors.teal.shade50,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal.shade800,
          indicatorColor: Colors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Plan de Parto'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Citas Prenatales'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          existingPlanAsync.when(
            data: (plan) {
              _populateBirthPlan(plan);
              return _buildBirthPlanTab();
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          _buildAppointmentsTab(),
        ],
      ),
    );
  }

  Widget _buildBirthPlanTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tus Preferencias para el Nacimiento',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Selecciona tus deseos y prioridades para compartirlos con tu equipo obstétrico.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),

        // Section 1: Acompañamiento
        _buildSectionHeader('1. Acompañamiento en el Parto', Icons.favorite),
        _buildCheckboxTile(
          title: 'Presencia continua de mi pareja / familiar',
          selected: _selectedCompanions.contains('partner_presence'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedCompanions.add('partner_presence')
                  : _selectedCompanions.remove('partner_presence');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Acompañamiento por Doula',
          selected: _selectedCompanions.contains('doula_presence'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedCompanions.add('doula_presence')
                  : _selectedCompanions.remove('doula_presence');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Acompañamiento en quirófano si es cesárea',
          selected: _selectedCompanions.contains('cesarean_companion'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedCompanions.add('cesarean_companion')
                  : _selectedCompanions.remove('cesarean_companion');
            });
          },
        ),

        const SizedBox(height: 16),

        // Section 2: Manejo del Dolor
        _buildSectionHeader('2. Alivio del Dolor', Icons.healing),
        _buildCheckboxTile(
          title: 'Epidural a libre demanda cuando la solicite',
          selected: _selectedPainManagement.contains('epidural_on_request'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPainManagement.add('epidural_on_request')
                  : _selectedPainManagement.remove('epidural_on_request');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Movimiento libre, caminar y pelota de esferodinamia',
          selected: _selectedPainManagement.contains('free_movement_ball'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPainManagement.add('free_movement_ball')
                  : _selectedPainManagement.remove('free_movement_ball');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Ducha o hidroterapia tibia',
          selected: _selectedPainManagement.contains('hydrotherapy'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPainManagement.add('hydrotherapy')
                  : _selectedPainManagement.remove('hydrotherapy');
            });
          },
        ),

        const SizedBox(height: 16),

        // Section 3: Entorno y Expulsivo
        _buildSectionHeader('3. Entorno y Expulsivo', Icons.spa),
        _buildCheckboxTile(
          title: 'Ambiente tranquilo: luz tenue y música suave',
          selected: _selectedEnvironment.contains('dim_lights_music'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedEnvironment.add('dim_lights_music')
                  : _selectedEnvironment.remove('dim_lights_music');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Libertad de postura en el pujo (no exclusivamente litotomía)',
          selected: _selectedEnvironment.contains('free_pushing_position'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedEnvironment.add('free_pushing_position')
                  : _selectedEnvironment.remove('free_pushing_position');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Pinzamiento y corte tardío del cordón umbilical',
          selected: _selectedEnvironment.contains('delayed_cord_clamping'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedEnvironment.add('delayed_cord_clamping')
                  : _selectedEnvironment.remove('delayed_cord_clamping');
            });
          },
        ),

        const SizedBox(height: 16),

        // Section 4: Posparto Inmediato
        _buildSectionHeader(
            '4. Primeras Horas Posparto (Golden Hour)', Icons.child_friendly),
        _buildCheckboxTile(
          title: 'Contacto piel con piel ininterrumpido en la primera hora',
          selected: _selectedPostpartum.contains('immediate_skin_to_skin'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPostpartum.add('immediate_skin_to_skin')
                  : _selectedPostpartum.remove('immediate_skin_to_skin');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Inicio temprano de la lactancia materna exclusiva',
          selected: _selectedPostpartum.contains('early_breastfeeding'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPostpartum.add('early_breastfeeding')
                  : _selectedPostpartum.remove('early_breastfeeding');
            });
          },
        ),
        _buildCheckboxTile(
          title: 'Alojamiento conjunto continuo sin separación',
          selected: _selectedPostpartum.contains('rooming_in'),
          onChanged: (val) {
            setState(() {
              val == true
                  ? _selectedPostpartum.add('rooming_in')
                  : _selectedPostpartum.remove('rooming_in');
            });
          },
        ),

        const SizedBox(height: 16),

        // Special Requests
        const Text(
          'Peticiones Especiales o Consideraciones Culturales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _specialRequestsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Ej. Deseo que mi pareja corte el cordón, alergia al látex, etc.',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: _saveBirthPlan,
          icon: const Icon(Icons.check),
          label: const Text('Guardar Mi Plan de Parto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAppointmentsTab() {
    final appointmentsAsync = ref.watch(prenatalAppointmentsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Agenda Prenatal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _showAddAppointmentDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva Cita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        appointmentsAsync.when(
          data: (appointments) {
            if (appointments.isEmpty) {
              return Card(
                color: Colors.grey.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No tienes citas prenatales programadas.\nPulsa "+ Nueva Cita" para agendar tu próximo control.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: appointments.map((apt) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semana ${apt.gestationalWeek} • ${apt.doctorOrClinic}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Checkbox(
                              value: apt.isCompleted,
                              onChanged: (val) async {
                                await ref
                                    .read(pregnancyRepositoryProvider)
                                    .toggleAppointmentCompletion(
                                        apt.id, val ?? false);
                                ref.invalidate(prenatalAppointmentsProvider);
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Fecha: ${apt.scheduledAt.toLocal().toString().substring(0, 16)}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (apt.topicsToDiscuss.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: apt.topicsToDiscuss.map((t) {
                              return Chip(
                                label: Text(t,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.teal.shade50,
                              );
                            }).toList(),
                          ),
                        ],
                        if (apt.notes != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Notas: ${apt.notes}',
                            style: const TextStyle(
                                fontStyle: FontStyle.italic, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error al cargar citas: $e'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool selected,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: selected,
      activeColor: Colors.teal,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
