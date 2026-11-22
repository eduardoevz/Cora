import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/fertility/domain/entities/fertility_chart_entity.dart';
import 'package:mobile/features/fertility/presentation/pages/preconception_checklist_page.dart';
import 'package:mobile/features/fertility/presentation/providers/fertility_providers.dart';
import 'package:mobile/features/fertility/presentation/widgets/bbt_biphasic_chart_widget.dart';
import 'package:mobile/features/onboarding/presentation/providers/identity_providers.dart';
import 'package:uuid/uuid.dart';

class ConceptionHubPage extends ConsumerStatefulWidget {
  const ConceptionHubPage({super.key});

  @override
  ConsumerState<ConceptionHubPage> createState() => _ConceptionHubPageState();
}

class _ConceptionHubPageState extends ConsumerState<ConceptionHubPage> {
  bool _showFahrenheit = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeUserProfileProvider);
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final chartDataAsync = ref.watch(fertilityChartDataProvider(profile.id));
    final tokens = CoraTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('Hub de Fertilidad y Concepción'),
        actions: [
          IconButton(
            icon: Icon(
              _showFahrenheit ? Icons.thermostat : Icons.device_thermostat,
              color: tokens.accentPrimary,
            ),
            tooltip: _showFahrenheit ? 'Cambiar a °C' : 'Cambiar a °F',
            onPressed: () => setState(() => _showFahrenheit = !_showFahrenheit),
          ),
          IconButton(
            icon: Icon(Icons.checklist, color: tokens.ovulatory),
            tooltip: 'Checklist Preconcepcional',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PreconceptionChecklistPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: chartDataAsync.when(
        data: (data) => _buildHubContent(context, profile.id, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('quick_log_fertility_fab'),
        onPressed: () => _openQuickLogSheet(context, profile.id),
        backgroundColor: tokens.accentPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Registrar Hoy',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHubContent(
      BuildContext context, String userId, FertilityCycleChartData data) {
    final tokens = CoraTheme.tokensOf(context);
    final bbtValues = data.dailyEntries
        .where((e) => e.bbtCelsius != null)
        .map((e) => e.bbtCelsius!)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
      children: [
        CoraStitchPageHeader(
          eyebrow: 'SEGUIMIENTO DE FERTILIDAD',
          title: 'Hub de Concepción',
          subtitle:
              'Temperatura basal bifásica, pico de LH y ventana fértil en tiempo real.',
          eyebrowIcon: Icons.biotech_outlined,
          trailing: CoraMintStatusPill(
            label: data.status == 'ovulation_confirmed'
                ? 'Ovulación Confirmada'
                : data.status == 'peak_fertility'
                    ? 'Pico Fértil'
                    : 'Seguimiento Activo',
            variant: CoraStatusPillVariant.mint,
          ),
        ),
        const SizedBox(height: 14),
        const CoraEditorialImageBanner(
          assetPath: 'assets/images/home_follicular_editorial.jpg',
          height: 94,
          topBadge: 'MÉTODO SINTOTÉRMICO CLÍNICO',
          bottomLeftBadge: 'Regla 3-sobre-6 • LH • Cérvix',
        ),
        const SizedBox(height: 14),
        // Status Card
        _buildStatusCard(context, data),
        const SizedBox(height: 12),
        if (bbtValues.length >= 2) ...[
          CoraSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Curva Térmica Basal (Tendencia)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                CoraBiometricTrendChart(
                  values: bbtValues,
                  referenceLine: data.coverlineCelsius,
                  lineColor: tokens.primaryDeep,
                  height: 76,
                  startLabel: 'Inicio',
                  endLabel: 'Hoy',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Age-based guidance banner if present
        if (data.activeSeekingGuidanceEs != null) ...[
          CoraAlertBanner(
            title: 'Orientación preconcepcional',
            description: data.activeSeekingGuidanceEs!,
            isUrgent: false,
          ),
          const SizedBox(height: 12),
        ],

        // Preconception Checklist Banner
        CoraInfoCallout(
          title: 'Checklist de Salud Preconcepcional',
          subtitle: 'Ácido fólico, exámenes serológicos y hábitos saludables.',
          badgeText: 'Abrir guía',
          phaseKey: 'ovulatory',
          icon: Icons.assignment_turned_in_outlined,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PreconceptionChecklistPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // BBT Chart
        BbtBiphasicChartWidget(
          cycleStartDate: data.cycleStartDate ?? DateTime.now(),
          entries: data.dailyEntries
              .map((p) => DailyFertilityEntity(
                    id: p.logDate.toIso8601String(),
                    userId: userId,
                    logDate: p.logDate,
                    bbtCelsius: p.bbtCelsius,
                    isDisturbed: p.isDisturbed,
                    disturbanceReason: p.disturbanceReason,
                    cervicalMucus: p.cervicalMucus,
                    lhResult: p.lhResult,
                    intercourseHad: p.intercourseHad,
                    intercourseType: p.intercourseType,
                  ))
              .toList(),
          coverlineCelsius: data.coverlineCelsius,
          showFahrenheit: _showFahrenheit,
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, FertilityCycleChartData data) {
    final tokens = CoraTheme.tokensOf(context);
    late final String phaseKey;
    late final IconData iconData;
    late final String statusTitle;

    switch (data.status) {
      case 'ovulation_confirmed':
        phaseKey = 'menstrual';
        iconData = Icons.verified;
        statusTitle = 'Ovulación Confirmada';
        break;
      case 'peak_fertility':
        phaseKey = 'follicular';
        iconData = Icons.star_outline_rounded;
        statusTitle = 'Pico de Fertilidad';
        break;
      case 'high':
        phaseKey = 'ovulatory';
        iconData = Icons.trending_up;
        statusTitle = 'Fertilidad Alta';
        break;
      case 'low':
      default:
        phaseKey = 'hormonally_managed';
        iconData = Icons.schedule;
        statusTitle = 'Fertilidad Baja';
        break;
    }

    final pair = tokens.phaseColors(phaseKey);

    return CoraSurfaceCard(
      key: const Key('conception_status_card'),
      backgroundColor: pair.background,
      borderColor: pair.border,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: pair.foreground.withValues(alpha: 0.14),
                child: Icon(iconData, color: pair.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: pair.foreground,
                          ),
                    ),
                    if (data.cycleDay != null)
                      Text(
                        'Día ${data.cycleDay} del ciclo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.evaluationNotesEs,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textPrimary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  void _openQuickLogSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuickFertilityLogSheet(userId: userId),
    ).then((_) {
      ref.invalidate(fertilityChartDataProvider(userId));
    });
  }
}

class _QuickFertilityLogSheet extends ConsumerStatefulWidget {
  final String userId;

  const _QuickFertilityLogSheet({required this.userId});

  @override
  ConsumerState<_QuickFertilityLogSheet> createState() =>
      _QuickFertilityLogSheetState();
}

class _QuickFertilityLogSheetState
    extends ConsumerState<_QuickFertilityLogSheet> {
  final _tempController = TextEditingController(text: '36.40');
  bool _isDisturbed = false;
  String _cervicalMucus = 'creamy';
  String _lhResult = 'negative';
  bool _intercourseHad = false;
  final String _intercourseType = 'unprotected';
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CoraTheme.tokensOf(context).borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registro Diario de Fertilidad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // BBT Field
            const Text(
              'Temperatura Basal (°C)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _tempController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ej. 36.45',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: '°C',
              ),
            ),
            const SizedBox(height: 12),

            // Disturbed switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Medición perturbada o fiebre'),
              subtitle: const Text('Insomnio, alcohol o enfermedad'),
              value: _isDisturbed,
              onChanged: (val) => setState(() => _isDisturbed = val),
            ),
            const SizedBox(height: 8),

            // Cervical Mucus Selector
            const Text(
              'Moco Cervical',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _cervicalMucus,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'dry', child: Text('Seco / Poco')),
                DropdownMenuItem(value: 'sticky', child: Text('Pegajoso')),
                DropdownMenuItem(value: 'creamy', child: Text('Cremoso')),
                DropdownMenuItem(
                    value: 'watery', child: Text('Acuoso (Fértil)')),
                DropdownMenuItem(
                    value: 'egg_white',
                    child: Text('Clara de huevo (Muy Fértil)')),
              ],
              onChanged: (val) =>
                  setState(() => _cervicalMucus = val ?? 'creamy'),
            ),
            const SizedBox(height: 12),

            // LH Selector
            const Text(
              'Tira Reactiva LH',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _lhResult,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'negative', child: Text('Negativo')),
                DropdownMenuItem(value: 'high', child: Text('Alto')),
                DropdownMenuItem(
                    value: 'peak', child: Text('Pico (Ovulatorio)')),
              ],
              onChanged: (val) => setState(() => _lhResult = val ?? 'negative'),
            ),
            const SizedBox(height: 12),

            // Intercourse Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Relación sexual o inseminación'),
              value: _intercourseHad,
              onChanged: (val) => setState(() => _intercourseHad = val),
            ),
            const SizedBox(height: 16),

            // Save button
            CoraPrimaryActionButton(
              onPressed: _saveDailyLog,
              label: 'Guardar Registro',
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDailyLog() async {
    final tempParsed = double.tryParse(_tempController.text.trim());
    final now = DateTime.now();

    final entry = DailyFertilityEntity(
      id: const Uuid().v4(),
      userId: widget.userId,
      logDate: now,
      bbtCelsius: tempParsed,
      isDisturbed: _isDisturbed,
      disturbanceReason: _isDisturbed ? 'Perturbación manual' : null,
      cervicalMucus: _cervicalMucus,
      lhResult: _lhResult,
      intercourseHad: _intercourseHad,
      intercourseType: _intercourseHad ? _intercourseType : 'none',
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final repo = ref.read(fertilityRepositoryProvider);
    await repo.saveDailyFertility(entry);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
