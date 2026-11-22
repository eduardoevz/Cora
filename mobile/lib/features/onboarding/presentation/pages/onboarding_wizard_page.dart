import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth/auth_providers.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/cycle/presentation/providers/cycle_providers.dart';
import 'package:mobile/features/onboarding/domain/entities/user_profile_entity.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:mobile/features/onboarding/presentation/widgets/initial_periods_calendar_picker.dart';
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
  bool _isCompleting = false;

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
  bool _clinicalContextCompleted = false;

  // Layer 4 (Menstrual Baseline for menstrual life stages)
  CycleRegularity _selectedRegularity = CycleRegularity.unsure;
  int _typicalCycleLengthDays = 28;
  InitialPeriodRangeEntity? _latestPeriod;
  InitialPeriodRangeEntity? _previousPeriod;

  bool get _isMenstrualStage =>
      _selectedLifeStage == LifeStage.adolescence ||
      _selectedLifeStage == LifeStage.regularAdult ||
      _selectedLifeStage == LifeStage.conceptionSearch ||
      _selectedLifeStage == LifeStage.perimenopause;

  int get _totalSteps => _isMenstrualStage ? 4 : 3;

  List<InitialPeriodRangeEntity> get _collectedInitialPeriods => [
        if (_previousPeriod != null) _previousPeriod!,
        if (_latestPeriod != null) _latestPeriod!,
      ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  bool _isStep1Valid() {
    final year = int.tryParse(_birthYearController.text.trim());
    final currentYear = DateTime.now().year;
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        year != null &&
        year >= 1920 &&
        year <= currentYear;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_isStep1Valid()) {
        setState(() => _currentStep = 1);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ingresa tu nombre, apellido y un año de nacimiento válido (1920–${DateTime.now().year}).',
            ),
          ),
        );
      }
    } else if (_currentStep == 1 && _selectedIntents.isNotEmpty) {
      setState(() => _currentStep = 2);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  UserProfileEntity _buildProfile({
    required bool clinicalCompleted,
    required bool includePeriods,
  }) {
    final birthYear = int.tryParse(_birthYearController.text.trim()) ?? 1996;
    final repo = ref.read(identityRepositoryProvider);
    final defaultModules = repo.getDefaultModulesForStage(_selectedLifeStage);

    final authUid = ref.read(coraAuthServiceProvider).currentUser?.uid;
    final resolvedUid =
        (authUid != null && authUid.isNotEmpty) ? authUid : const Uuid().v4();

    final periods = _isMenstrualStage && includePeriods
        ? _collectedInitialPeriods
        : const <InitialPeriodRangeEntity>[];
    final inferredBleeding = periods.isEmpty
        ? null
        : (periods.map((e) => e.bleedingDurationDays).reduce((a, b) => a + b) /
                periods.length)
            .round();

    return UserProfileEntity(
      id: const Uuid().v4(),
      firebaseUid: resolvedUid,
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
        cycleRegularity: _isMenstrualStage
            ? _selectedRegularity
            : CycleRegularity.notApplicable,
        typicalCycleLengthDays:
            _isMenstrualStage ? _typicalCycleLengthDays : null,
        typicalBleedingDurationDays:
            _isMenstrualStage ? inferredBleeding : null,
        initialPeriods: periods,
      ),
      enabledModules: defaultModules,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _complete({
    required bool clinicalCompleted,
    bool includePeriods = true,
  }) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      final profile = _buildProfile(
        clinicalCompleted: clinicalCompleted,
        includePeriods: includePeriods,
      );

      if (widget.onCompleted != null) {
        ref.read(activeUserProfileProvider.notifier).state = profile;
        widget.onCompleted!(profile);
      } else {
        final saved = await ref
            .read(identityRepositoryProvider)
            .completeOnboarding(profile);
        if (_isMenstrualStage &&
            includePeriods &&
            profile.onboardingContext.initialPeriods.isNotEmpty) {
          await ref.read(cycleRepositoryProvider).seedInitialPeriods(
                userId: saved.id,
                periods: profile.onboardingContext.initialPeriods,
                cycleRegularity: saved.onboardingContext.cycleRegularity,
                typicalCycleLengthDays:
                    saved.onboardingContext.typicalCycleLengthDays,
                typicalBleedingDurationDays:
                    saved.onboardingContext.typicalBleedingDurationDays,
                syncRemote: false,
              );
          ref.invalidate(cycleOverviewProvider);
          ref.invalidate(cycleHistoryProvider);
          ref.invalidate(cycleCalendarMonthProvider);
        }
        ref.read(activeUserProfileProvider.notifier).state = saved;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible guardar tu perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
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
              if (_currentStep == 3) _buildLayer4(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final tokens = CoraTheme.tokensOf(context);
    final total = _totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASO ${_currentStep + 1} DE $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.accentPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              _selectedLifeStage.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(total, (index) {
            final isActive = index <= _currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index < total - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  color:
                      isActive ? tokens.accentPrimary : tokens.surfaceSecondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLayer1() {
    final tokens = CoraTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cómo te llamas?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Queremos acompañarte de manera personalizada en cada paso.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        const SizedBox(height: 14),
        CoraSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('first_name_input'),
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('last_name_input'),
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('birth_year_input'),
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Año de nacimiento (ej. 1996)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LifeStage>(
                key: const Key('life_stage_dropdown'),
                initialValue: _selectedLifeStage,
                decoration: const InputDecoration(
                  labelText: 'Etapa de vida inicial',
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        CoraPrimaryActionButton(
          key: const Key('next_step_button'),
          label: 'Continuar',
          icon: Icons.arrow_forward_rounded,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildLayer2() {
    final tokens = CoraTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué te gustaría priorizar hoy?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona entre 1 y 3 prioridades principales.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        const SizedBox(height: 14),
        CoraSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PrimaryIntent.values.map((intent) {
              final isSelected = _selectedIntents.contains(intent);
              return FilterChip(
                key: Key('intent_${intent.value}'),
                label: Text(intent.label),
                selected: isSelected,
                selectedColor: tokens.accentSurface,
                checkmarkColor: tokens.accentPrimary,
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
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('next_step_button'),
          onPressed:
              (_selectedIntents.isNotEmpty && _selectedIntents.length <= 3)
                  ? _nextStep
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.accentPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('Siguiente'),
        ),
      ],
    );
  }

  Widget _buildLayer3() {
    final tokens = CoraTheme.tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contexto Clínico Base',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Esta información nos ayuda a calibrar los algoritmos biomédicos. Es completamente opcional y puedes completarla más tarde.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        CoraSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<HormonalMethod>(
                initialValue: _selectedHormonalMethod,
                decoration: const InputDecoration(
                  labelText: 'Método anticonceptivo / hormonal actual',
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
              const SizedBox(height: 12),
              Text(
                'Condiciones diagnosticadas (opcional):',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
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
                    selectedColor: tokens.accentSurface,
                    checkmarkColor: tokens.accentPrimary,
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
            ],
          ),
        ),
        const SizedBox(height: 14),
        CoraPrimaryActionButton(
          key: Key(
            _isMenstrualStage
                ? 'layer_three_continue_button'
                : 'complete_onboarding_button',
          ),
          label: _isMenstrualStage ? 'Continuar' : 'Finalizar Configuración',
          icon: _isMenstrualStage
              ? Icons.arrow_forward_rounded
              : Icons.check_rounded,
          isLoading: _isCompleting,
          onPressed: _isMenstrualStage
              ? () {
                  setState(() {
                    _clinicalContextCompleted = true;
                    _currentStep = 3;
                  });
                }
              : () => _complete(clinicalCompleted: true),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('skip_layer_three_button'),
          onPressed: _isMenstrualStage
              ? () {
                  setState(() {
                    _clinicalContextCompleted = false;
                    _currentStep = 3;
                  });
                }
              : () => _complete(clinicalCompleted: false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Responder después'),
        ),
      ],
    );
  }

  Widget _buildLayer4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CoraStitchPageHeader(
          eyebrow: 'CALIBRACIÓN BIOLÓGICA',
          title: 'Tu Línea Base Menstrual',
          subtitle:
              'Selecciona tus últimos 2 periodos en el calendario y tu regularidad para calibrar tus predicciones.',
          eyebrowIcon: Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 16),
        InitialPeriodsCalendarPicker(
          lifeStage: _selectedLifeStage,
          diagnosedConditions: _selectedConditions.toList(),
          regularity: _selectedRegularity,
          cycleLengthDays: _typicalCycleLengthDays,
          latestPeriod: _latestPeriod,
          previousPeriod: _previousPeriod,
          onRegularityChanged: (reg) {
            setState(() => _selectedRegularity = reg);
          },
          onCycleLengthChanged: (len) {
            setState(() => _typicalCycleLengthDays = len);
          },
          onLatestPeriodChanged: (range) {
            setState(() => _latestPeriod = range);
          },
          onPreviousPeriodChanged: (range) {
            setState(() => _previousPeriod = range);
          },
        ),
        const SizedBox(height: 14),
        CoraBlushInsetBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.science_outlined,
                size: 18,
                color: CoraTheme.tokensOf(context).primaryDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precisión ginecológica',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dos ciclos permiten delimitar la longitud real de tu fase lútea para anticipar ovulación y próximo periodo.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CoraTheme.tokensOf(context).textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        CoraPrimaryActionButton(
          key: const Key('complete_onboarding_button'),
          label: 'Finalizar Configuración',
          icon: Icons.check_rounded,
          isLoading: _isCompleting,
          onPressed: () => _complete(
            clinicalCompleted: _clinicalContextCompleted,
            includePeriods: true,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('skip_layer_four_button'),
          onPressed: () => _complete(
            clinicalCompleted: _clinicalContextCompleted,
            includePeriods: false,
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('No recuerdo mis fechas por ahora'),
        ),
      ],
    );
  }
}
