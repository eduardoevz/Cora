import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';

class ModulePreferencesPage extends ConsumerStatefulWidget {
  final UserProfileEntity profile;

  const ModulePreferencesPage({super.key, required this.profile});

  @override
  ConsumerState<ModulePreferencesPage> createState() =>
      _ModulePreferencesPageState();
}

class _ModulePreferencesPageState extends ConsumerState<ModulePreferencesPage> {
  late Set<String> _enabledModules;
  bool _isSaving = false;

  static const Map<String, String> _availableModules = {
    'cycle_tracking': 'Seguimiento del Ciclo Menstrual',
    'ovulation_prediction': 'Predicción de Ovulación',
    'symptom_diary': 'Diario de Síntomas y Bienestar',
    'contraceptive_management': 'Control Anticonceptivo',
    'fertility_bbt': 'Temperatura Basal y Fertilidad',
    'lh_surge_prediction': 'Predicción de Pico LH',
    'cervical_mucus': 'Monitoreo de Moco Cervical',
    'fetal_development': 'Desarrollo Fetal Semana a Semana',
    'maternal_vitals': 'Signos Vitales Maternos y Tensión',
    'kick_counter': 'Contador de Pataditas',
    'birth_plan': 'Plan de Parto ACOG',
    'postpartum_lochia': 'Monitoreo de Loquios y Recuperación',
    'pelvic_floor': 'Suelo Pélvico y Rehabilitación',
    'epds_screening': 'Tamizaje Emocional Posparto (EPDS)',
    'breastfeeding_tracker': 'Registro de Lactancia',
    'vasomotor_hot_flashes': 'Control de Sofocos y Síntomas Vasomotores',
    'cycle_variability': 'Variabilidad Menstrual STRAW+10',
    'sleep_and_mood': 'Sueño y Estabilidad Emocional',
    'hormone_therapy': 'Seguimiento de Terapia Hormonal (TRH)',
    'bone_muscle_health': 'Salud Ósea y Muscular',
    'urogynecology': 'Prevención Uroginecológica',
    'cardiovascular_prevention': 'Prevención Cardiovascular',
    'preventive_checkups': 'Chequeos Preventivos Periódicos',
    'education_body_basics': 'Educación: Conoce tu Cuerpo',
    'wellness': 'Bienestar y Hábitos Saludables',
    'partner_sharing': 'Partner View (Sincronización en Pareja)',
  };

  @override
  void initState() {
    super.initState();
    _enabledModules = widget.profile.enabledModules.toSet();
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final updated =
          await ref.read(identityRepositoryProvider).updateModulePreferences(
                profileId: widget.profile.id,
                modules: _enabledModules.toList(),
              );

      ref.read(activeUserProfileProvider.notifier).state = updated;

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Módulos actualizados correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar módulos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos a la Carta'),
        actions: [
          TextButton(
            key: const Key('save_module_preferences_button'),
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _availableModules.entries.map((entry) {
          final isEnabled = _enabledModules.contains(entry.key);
          return SwitchListTile(
            key: Key('toggle_module_${entry.key}'),
            title: Text(entry.value),
            subtitle: Text('Clave: ${entry.key}'),
            value: isEnabled,
            onChanged: (val) {
              setState(() {
                if (val) {
                  _enabledModules.add(entry.key);
                } else {
                  _enabledModules.remove(entry.key);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
