import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:uuid/uuid.dart';

class OnboardingWizardPage extends ConsumerStatefulWidget {
  final void Function(UserProfileEntity profile)? onCompleted;

  const OnboardingWizardPage({super.key, this.onCompleted});

  @override
  ConsumerState<OnboardingWizardPage> createState() =>
      _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  int _currentStep = 0;

  // Layer 1
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  LifeStage _selectedLifeStage = LifeStage.regularAdult;

  // Layer 2
  final Set<PrimaryIntent> _selectedIntents = {};

  // Layer 3
  HormonalMethod _selectedHormonalMethod = HormonalMethod.none;
  final Set<DiagnosedCondition> _selectedConditions = {};

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  bool _isStep1Valid() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        int.tryParse(_birthYearController.text.trim()) != null;
  }

  void _nextStep() {
    if (_currentStep == 0 && _isStep1Valid()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _selectedIntents.isNotEmpty) {
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  UserProfileEntity _buildProfile({required bool clinicalCompleted}) {
    final birthYear = int.tryParse(_birthYearController.text.trim()) ?? 1996;
    final repo = ref.read(identityRepositoryProvider);
    final defaultModules = repo.getDefaultModulesForStage(_selectedLifeStage);

    return UserProfileEntity(
      id: const Uuid().v4(),
      firebaseUid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      currentLifeStage: _selectedLifeStage,
      onboardingCompleted: true,
      onboardingContext: OnboardingContextEntity(
        birthYear: birthYear,
        primaryIntents: _selectedIntents.toList(),
        hormonalMethod: clinicalCompleted ? _selectedHormonalMethod : null,
        diagnosedConditions:
            clinicalCompleted ? _selectedConditions.toList() : const [],
        clinicalContextCompleted: clinicalCompleted,
      ),
      enabledModules: defaultModules,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _complete({required bool clinicalCompleted}) async {
    final profile = _buildProfile(clinicalCompleted: clinicalCompleted);

    ref.read(activeUserProfileProvider.notifier).state = profile;

    if (widget.onCompleted != null) {
      widget.onCompleted!(profile);
    } else {
      await ref.read(identityRepositoryProvider).completeOnboarding(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenida a Cora'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 16),
              if (_currentStep == 0) _buildLayer1(),
              if (_currentStep == 1) _buildLayer2(),
              if (_currentStep == 2) _buildLayer3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLayer1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cómo te llamas?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Queremos acompañarte de manera personalizada en cada paso.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('first_name_input'),
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('last_name_input'),
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Apellido',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('birth_year_input'),
          controller: _birthYearController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Año de nacimiento (ej. 1996)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<LifeStage>(
          key: const Key('life_stage_dropdown'),
          initialValue: _selectedLifeStage,
          decoration: const InputDecoration(
            labelText: 'Etapa de vida inicial',
            border: OutlineInputBorder(),
          ),
          items: LifeStage.values.map((stage) {
            return DropdownMenuItem(
              value: stage,
              child: Text(stage.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedLifeStage = val);
            }
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          key: const Key('next_step_button'),
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildLayer2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué te gustaría priorizar hoy?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona entre 1 y 3 prioridades principales.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: PrimaryIntent.values.map((intent) {
            final isSelected = _selectedIntents.contains(intent);
            return FilterChip(
              key: Key('intent_${intent.value}'),
              label: Text(intent.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (_selectedIntents.length >= 3) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Máximo 3 intenciones seleccionadas'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() => _selectedIntents.add(intent));
                } else {
                  setState(() => _selectedIntents.remove(intent));
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          key: const Key('next_step_button'),
          onPressed:
              (_selectedIntents.isNotEmpty && _selectedIntents.length <= 3)
                  ? _nextStep
                  : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Siguiente'),
        ),
      ],
    );
  }

  Widget _buildLayer3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contexto Clínico Base',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Esta información nos ayuda a calibrar los algoritmos biomédicos. Es completamente opcional y puedes completarla más tarde.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HormonalMethod>(
          initialValue: _selectedHormonalMethod,
          decoration: const InputDecoration(
            labelText: 'Método anticonceptivo / hormonal actual',
            border: OutlineInputBorder(),
          ),
          items: HormonalMethod.values.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(m.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedHormonalMethod = val);
            }
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Condiciones diagnosticadas (opcional):',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: DiagnosedCondition.values.map((cond) {
            final isSelected = _selectedConditions.contains(cond);
            return FilterChip(
              key: Key('condition_${cond.value}'),
              label: Text(cond.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (cond == DiagnosedCondition.none) {
                      _selectedConditions.clear();
                      _selectedConditions.add(cond);
                    } else {
                      _selectedConditions.remove(DiagnosedCondition.none);
                      _selectedConditions.add(cond);
                    }
                  } else {
                    _selectedConditions.remove(cond);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          key: const Key('complete_onboarding_button'),
          onPressed: () => _complete(clinicalCompleted: true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Finalizar Configuración'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('skip_layer_three_button'),
          onPressed: () => _complete(clinicalCompleted: false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Responder después'),
        ),
      ],
    );
  }
}
