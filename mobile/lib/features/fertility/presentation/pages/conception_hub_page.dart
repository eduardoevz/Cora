import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hub de Fertilidad y Concepción'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFahrenheit ? Icons.thermostat : Icons.device_thermostat,
              color: const Color(0xFFE11D48),
            ),
            tooltip: _showFahrenheit ? 'Cambiar a °C' : 'Cambiar a °F',
            onPressed: () => setState(() => _showFahrenheit = !_showFahrenheit),
          ),
          IconButton(
            icon: const Icon(Icons.checklist, color: Color(0xFF2563EB)),
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
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Registrar Hoy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHubContent(
      BuildContext context, String userId, FertilityCycleChartData data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // Status Card
        _buildStatusCard(data),
        const SizedBox(height: 12),

        // Age-based guidance banner if present
        if (data.activeSeekingGuidanceEs != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.activeSeekingGuidanceEs!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Preconception Checklist Banner
        Card(
          elevation: 0,
          color: const Color(0xFFF0FDF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF16A34A),
              child: Icon(Icons.assignment_turned_in, color: Colors.white),
            ),
            title: const Text(
              'Checklist de Salud Preconcepcional',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Ácido fólico, exámenes serológicos y hábitos saludables.',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PreconceptionChecklistPage(),
                ),
              );
            },
          ),
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

  Widget _buildStatusCard(FertilityCycleChartData data) {
    Color cardColor;
    Color borderColor;
    Color iconColor;
    IconData iconData;
    String statusTitle;

    switch (data.status) {
      case 'ovulation_confirmed':
        cardColor = const Color(0xFFFDF2F8);
        borderColor = const Color(0xFFFBCFE8);
        iconColor = const Color(0xFFE11D48);
        iconData = Icons.verified;
        statusTitle = 'Ovulación Confirmada';
        break;
      case 'peak_fertility':
        cardColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.star;
        statusTitle = 'Pico de Fertilidad';
        break;
      case 'high':
        cardColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        iconColor = const Color(0xFF059669);
        iconData = Icons.trending_up;
        statusTitle = 'Fertilidad Alta';
        break;
      case 'low':
      default:
        cardColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        iconColor = const Color(0xFF64748B);
        iconData = Icons.schedule;
        statusTitle = 'Fertilidad Baja';
        break;
    }

    return Card(
      key: const Key('conception_status_card'),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(iconData, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: iconColor,
                        ),
                      ),
                      if (data.cycleDay != null)
                        Text(
                          'Día ${data.cycleDay} del ciclo',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
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
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ],
        ),
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
    _tempController.dispose() ;
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
                  color: Colors.grey.shade300,
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
                DropdownMenuItem(value: 'watery', child: Text('Acuoso (Fértil)')),
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
                DropdownMenuItem(value: 'peak', child: Text('Pico (Ovulatorio)')),
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveDailyLog,
                child: const Text('Guardar Registro',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
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
