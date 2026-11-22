import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/cora_design_components.dart';
import 'package:mobile/core/theme/cora_theme.dart';
import 'package:mobile/features/pregnancy/domain/entities/pregnancy_entities.dart';
import 'package:mobile/features/pregnancy/presentation/providers/pregnancy_providers.dart';
import 'package:uuid/uuid.dart';

class ContractionAndKickTimersPage extends ConsumerStatefulWidget {
  final PregnancyEpisodeEntity episode;
  final int gestationalWeeks;

  const ContractionAndKickTimersPage({
    super.key,
    required this.episode,
    required this.gestationalWeeks,
  });

  @override
  ConsumerState<ContractionAndKickTimersPage> createState() =>
      _ContractionAndKickTimersPageState();
}

class _ContractionAndKickTimersPageState
    extends ConsumerState<ContractionAndKickTimersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Contraction State
  bool _isContracting = false;
  DateTime? _contractionStartTime;
  Timer? _contractionTicker;
  int _currentContractionSeconds = 0;
  final List<Map<String, dynamic>> _currentContractions = [];
  String _selectedIntensity = 'moderate';

  // Kick State
  bool _isKickSessionActive = false;
  DateTime? _kickSessionStartTime;
  Timer? _kickTicker;
  int _kickElapsedMinutes = 0;
  int _kicksCount = 0;
  int? _targetReachedAtMinutes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _contractionTicker?.cancel();
    _kickTicker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleContraction() {
    final now = DateTime.now();
    if (!_isContracting) {
      setState(() {
        _isContracting = true;
        _contractionStartTime = now;
        _currentContractionSeconds = 0;
      });
      _contractionTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _currentContractionSeconds =
              DateTime.now().difference(_contractionStartTime!).inSeconds;
        });
      });
    } else {
      _contractionTicker?.cancel();
      final duration = _currentContractionSeconds;
      final start = _contractionStartTime ?? now;
      setState(() {
        _isContracting = false;
        _currentContractions.add({
          'started_at': start.toIso8601String(),
          'duration_seconds': duration,
          'intensity': _selectedIntensity,
        });
        _currentContractionSeconds = 0;
        _contractionStartTime = null;
      });
    }
  }

  Future<void> _saveContractionSession() async {
    if (_currentContractions.isEmpty) return;

    final evaluation = MaternalOfflineEvaluator.evaluateContractions(
      events: _currentContractions,
      gestationalWeeks: widget.gestationalWeeks,
    );

    final session = ContractionSessionEntity(
      id: const Uuid().v4(),
      pregnancyEpisodeId: widget.episode.id,
      startedAt:
          DateTime.parse(_currentContractions.first['started_at'] as String),
      endedAt: DateTime.now(),
      gestationalWeeks: widget.gestationalWeeks,
      pattern: evaluation.pattern,
      totalContractions: evaluation.totalContractions,
      avgIntervalSeconds: evaluation.avgIntervalMinutes * 60,
      avgDurationSeconds: evaluation.avgDurationSeconds,
      events: List.from(_currentContractions),
      alert: evaluation.alert,
    );

    final repo = ref.read(pregnancyRepositoryProvider);
    await repo.saveContractionSession(session);
    ref.invalidate(contractionSessionsProvider);

    setState(() {
      _currentContractions.clear();
    });

    if (mounted) {
      final tokens = CoraTheme.tokensOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sesión de contracciones guardada con éxito.'),
          backgroundColor: tokens.follicular,
        ),
      );
    }
  }

  void _toggleKickSession() {
    final now = DateTime.now();
    if (!_isKickSessionActive) {
      setState(() {
        _isKickSessionActive = true;
        _kickSessionStartTime = now;
        _kickElapsedMinutes = 0;
        _kicksCount = 0;
        _targetReachedAtMinutes = null;
      });
      _kickTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
        final elapsed =
            DateTime.now().difference(_kickSessionStartTime!).inMinutes;
        if (elapsed != _kickElapsedMinutes) {
          setState(() {
            _kickElapsedMinutes = elapsed;
          });
        }
      });
    } else {
      _kickTicker?.cancel();
      setState(() {
        _isKickSessionActive = false;
      });
    }
  }

  void _recordKick() {
    if (!_isKickSessionActive) {
      _toggleKickSession();
    }
    setState(() {
      _kicksCount++;
      if (_kicksCount == 10 && _targetReachedAtMinutes == null) {
        _targetReachedAtMinutes = _kickElapsedMinutes;
      }
    });
  }

  Future<void> _saveKickSession() async {
    if (_kicksCount == 0 && _kickElapsedMinutes == 0) return;

    final evaluation = MaternalOfflineEvaluator.evaluateKicks(
      kicksCount: _kicksCount,
      durationMinutes: _kickElapsedMinutes,
    );

    final session = KickSessionEntity(
      id: const Uuid().v4(),
      pregnancyEpisodeId: widget.episode.id,
      startedAt: _kickSessionStartTime ?? DateTime.now(),
      durationMinutes: _kickElapsedMinutes,
      gestationalWeeks: widget.gestationalWeeks,
      kicksCount: _kicksCount,
      targetReached: evaluation.targetReached,
      targetReachedAtMinutes: _targetReachedAtMinutes,
      isReassuring: evaluation.isReassuring,
      alert: evaluation.alert,
    );

    final repo = ref.read(pregnancyRepositoryProvider);
    await repo.saveKickSession(session);
    ref.invalidate(kickSessionsProvider);

    _kickTicker?.cancel();
    setState(() {
      _isKickSessionActive = false;
      _kickSessionStartTime = null;
      _kickElapsedMinutes = 0;
      _kicksCount = 0;
      _targetReachedAtMinutes = null;
    });

    if (mounted) {
      final tokens = CoraTheme.tokensOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Sesión de movimientos fetales guardada con éxito.'),
          backgroundColor: tokens.follicular,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CoraTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracciones y Patadas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: tokens.luteal,
          unselectedLabelColor: tokens.textSecondary,
          indicatorColor: tokens.luteal,
          tabs: const [
            Tab(
                icon: Icon(Icons.timer_outlined),
                text: 'Contracciones (5-1-1)'),
            Tab(
                icon: Icon(Icons.child_care_outlined),
                text: 'Contador Cardiff (10)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContractionsTab(),
          _buildKicksTab(),
        ],
      ),
    );
  }

  Widget _buildContractionsTab() {
    final tokens = CoraTheme.tokensOf(context);
    final evaluation = MaternalOfflineEvaluator.evaluateContractions(
      events: _currentContractions,
      gestationalWeeks: widget.gestationalWeeks,
    );
    final historyAsync = ref.watch(contractionSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer Card
        CoraSurfaceCard(
          backgroundColor:
              _isContracting ? tokens.menstrualSurface : tokens.surface,
          borderColor: _isContracting
              ? tokens.menstrual.withValues(alpha: 0.4)
              : tokens.borderSubtle,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            children: [
              Text(
                _isContracting
                    ? 'Contracción en Curso'
                    : 'Listo para medir contracción',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _isContracting
                          ? tokens.menstrual
                          : tokens.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatSeconds(_currentContractionSeconds),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _isContracting
                          ? tokens.menstrual
                          : tokens.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Leve'),
                    selected: _selectedIntensity == 'mild',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIntensity = 'mild');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Moderada'),
                    selected: _selectedIntensity == 'moderate',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIntensity = 'moderate');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Intensa'),
                    selected: _selectedIntensity == 'strong',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIntensity = 'strong');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _toggleContraction,
                icon: Icon(_isContracting ? Icons.stop : Icons.play_arrow),
                label: Text(_isContracting
                    ? 'Detener Contracción'
                    : 'Iniciar Contracción'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isContracting ? tokens.menstrual : tokens.luteal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Assessment
        if (_currentContractions.isNotEmpty) ...[
          _buildContractionEvaluationCard(evaluation),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contracciones en esta sesión (${_currentContractions.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              ElevatedButton.icon(
                onPressed: _saveContractionSession,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Guardar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.follicular,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._currentContractions.reversed.map((c) {
            final dur = c['duration_seconds'] as int;
            final intensity = c['intensity'] as String;
            final time = DateTime.parse(c['started_at'] as String);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CoraSurfaceCard(
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tokens.lutealSurface,
                      child: Text(
                        '${dur}s',
                        style: TextStyle(
                          color: tokens.luteal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    title: Text(
                      'Hora: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    subtitle: Text(
                        'Intensidad: $intensity • Duración: $dur segundos'),
                  ),
                ),
              ),
            );
          }),
        ],

        const SizedBox(height: 20),
        const CoraSectionLabel(title: 'Historial de Sesiones Anteriores'),
        const SizedBox(height: 8),
        historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Text(
                'No hay sesiones de contracciones previas guardadas.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
              );
            }
            return Column(
              children: sessions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CoraSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(Icons.history, color: tokens.luteal),
                        title: Text(
                          '${s.totalContractions} contracciones • Patrón: ${s.pattern}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Promedio: ${s.avgIntervalSeconds != null ? (s.avgIntervalSeconds! ~/ 60) : 0}m intervalo, ${s.avgDurationSeconds?.toStringAsFixed(0) ?? "0"}s duración\n${s.startedAt.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error al cargar historial: $e'),
        ),
      ],
    );
  }

  Widget _buildContractionEvaluationCard(
      ({
        String pattern,
        MaternalAlertEntity? alert,
        double avgIntervalMinutes,
        double avgDurationSeconds,
        int totalContractions,
      }) eval) {
    final isUrgent = eval.alert?.severity == 'urgent_emergency';
    final isPriority = eval.alert?.severity == 'priority_consult';
    return CoraAlertBanner(
      title: eval.alert?.title ?? 'Evaluación de Dinámica Uterina',
      description: eval.alert?.message ??
          'Frecuencia: cada ${eval.avgIntervalMinutes.toStringAsFixed(1)} min • Duración: ${eval.avgDurationSeconds.toStringAsFixed(0)} seg.',
      recommendation: eval.alert?.actionRecommended != null
          ? 'Recomendación: ${eval.alert!.actionRecommended}'
          : null,
      isUrgent: isUrgent,
      icon: isUrgent
          ? Icons.warning_amber_rounded
          : (isPriority ? Icons.notifications_active : Icons.info_outline),
    );
  }

  Widget _buildKicksTab() {
    final tokens = CoraTheme.tokensOf(context);
    final eval = MaternalOfflineEvaluator.evaluateKicks(
      kicksCount: _kicksCount,
      durationMinutes: _kickElapsedMinutes,
    );
    final historyAsync = ref.watch(kickSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kick Counter Card
        CoraSurfaceCard(
          backgroundColor: tokens.lutealSurface,
          borderColor: tokens.luteal.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiempo: $_kickElapsedMinutes min',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.luteal,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    _isKickSessionActive ? 'Sesión en curso' : 'Sesión pausada',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isKickSessionActive
                              ? tokens.follicular
                              : tokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$_kicksCount / 10',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color:
                          _kicksCount >= 10 ? tokens.follicular : tokens.luteal,
                    ),
              ),
              Text(
                'Meta Cardiff: 10 patadas en <= 120 min',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_kicksCount / 10).clamp(0.0, 1.0),
                  backgroundColor: tokens.surface,
                  color: _kicksCount >= 10 ? tokens.follicular : tokens.luteal,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _recordKick,
                icon: const Icon(Icons.touch_app_outlined, size: 22),
                label: const Text('+1 Patada Fetal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.luteal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _toggleKickSession,
                    icon: Icon(
                        _isKickSessionActive ? Icons.pause : Icons.play_arrow),
                    label: Text(_isKickSessionActive
                        ? 'Pausar Cronómetro'
                        : 'Iniciar Tiempo'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: (_kicksCount > 0 || _kickElapsedMinutes > 0)
                        ? _saveKickSession
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.follicular,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Live Evaluation Alert
        if (eval.targetReached) ...[
          CoraSurfaceCard(
            backgroundColor: tokens.follicularSurface,
            borderColor: tokens.follicular.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: tokens.follicular, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¡Meta alcanzada! Patrón fetal tranquilizador. 10 movimientos registrados.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.follicular,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else if (eval.alert != null) ...[
          CoraAlertBanner(
            title: eval.alert!.title,
            description: eval.alert!.message,
            recommendation: 'Recomendación: ${eval.alert!.actionRecommended}',
            isUrgent: true,
          ),
          const SizedBox(height: 16),
        ],

        const CoraSectionLabel(title: 'Historial de Sesiones de Patadas'),
        const SizedBox(height: 8),
        historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Text(
                'No hay sesiones de patadas guardadas.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.textSecondary),
              );
            }
            return Column(
              children: sessions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CoraSurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: s.isReassuring
                              ? tokens.follicularSurface
                              : tokens.alertUrgent.withValues(alpha: 0.12),
                          child: Icon(
                            s.isReassuring ? Icons.check : Icons.warning_amber,
                            color: s.isReassuring
                                ? tokens.follicular
                                : tokens.alertUrgent,
                          ),
                        ),
                        title: Text(
                          '${s.kicksCount} patadas en ${s.durationMinutes} min',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        subtitle: Text(
                          '${s.isReassuring ? "Patrón tranquilizador" : "Disminución reportada"} • ${s.startedAt.toLocal().toString().substring(0, 16)}',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error al cargar historial: $e'),
        ),
      ],
    );
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
