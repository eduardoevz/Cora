import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      startedAt: DateTime.parse(_currentContractions.first['started_at'] as String),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión de contracciones guardada con éxito.'),
          backgroundColor: Colors.teal,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión de movimientos fetales guardada con éxito.'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contracciones y Patadas'),
        backgroundColor: Colors.purple.shade50,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple.shade800,
          indicatorColor: Colors.purple,
          tabs: const [
            Tab(icon: Icon(Icons.timer), text: 'Contracciones (5-1-1)'),
            Tab(icon: Icon(Icons.child_care), text: 'Contador Cardiff (10)'),
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
    final evaluation = MaternalOfflineEvaluator.evaluateContractions(
      events: _currentContractions,
      gestationalWeeks: widget.gestationalWeeks,
    );
    final historyAsync = ref.watch(contractionSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: _isContracting ? Colors.pink.shade50 : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Text(
                  _isContracting
                      ? 'Contracción en Curso'
                      : 'Listo para medir contracción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isContracting ? Colors.pink.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatSeconds(_currentContractionSeconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: _isContracting ? Colors.pink.shade600 : Colors.grey.shade700,
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
                        if (selected) setState(() => _selectedIntensity = 'mild');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Moderada'),
                      selected: _selectedIntensity == 'moderate',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedIntensity = 'moderate');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Intensa'),
                      selected: _selectedIntensity == 'strong',
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedIntensity = 'strong');
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
                    backgroundColor: _isContracting ? Colors.pink.shade600 : Colors.purple,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ElevatedButton.icon(
                onPressed: _saveContractionSession,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Text('${dur}s',
                      style: TextStyle(
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                title: Text(
                    'Hora: ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'),
                subtitle: Text('Intensidad: $intensity • Duración: $dur segundos'),
              ),
            );
          }),
        ],

        const SizedBox(height: 24),
        const Text(
          'Historial de Sesiones Anteriores',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Text(
                'No hay sesiones de contracciones previas guardadas.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Column(
              children: sessions.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.purple),
                    title: Text(
                      '${s.totalContractions} contracciones • Patrón: ${s.pattern}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Promedio: ${s.avgIntervalSeconds != null ? (s.avgIntervalSeconds! ~/ 60) : 0}m intervalo, ${s.avgDurationSeconds?.toStringAsFixed(0) ?? "0"}s duración\n${s.startedAt.toLocal().toString().substring(0, 16)}',
                    ),
                    isThreeLine: true,
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

  Widget _buildContractionEvaluationCard(({
    String pattern,
    MaternalAlertEntity? alert,
    double avgIntervalMinutes,
    double avgDurationSeconds,
    int totalContractions,
  }) eval) {
    Color cardColor = Colors.blue.shade50;
    Color borderColor = Colors.blue.shade300;
    IconData icon = Icons.info_outline;

    if (eval.alert?.severity == 'urgent_emergency') {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade400;
      icon = Icons.warning_amber_rounded;
    } else if (eval.alert?.severity == 'priority_consult') {
      cardColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade600;
      icon = Icons.notifications_active;
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: borderColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    eval.alert?.title ?? 'Evaluación de Dinámica Uterina',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: eval.alert?.severity == 'urgent_emergency'
                          ? Colors.red.shade900
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eval.alert?.message ??
                  'Frecuencia: cada ${eval.avgIntervalMinutes.toStringAsFixed(1)} min • Duración: ${eval.avgDurationSeconds.toStringAsFixed(0)} seg.',
              style: const TextStyle(fontSize: 14),
            ),
            if (eval.alert?.actionRecommended != null) ...[
              const SizedBox(height: 8),
              Text(
                'Recomendación: ${eval.alert!.actionRecommended}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKicksTab() {
    final eval = MaternalOfflineEvaluator.evaluateKicks(
      kicksCount: _kicksCount,
      durationMinutes: _kickElapsedMinutes,
    );
    final historyAsync = ref.watch(kickSessionsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kick Counter Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiempo: $_kickElapsedMinutes min',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    Text(
                      _isKickSessionActive ? 'Sesión en curso' : 'Sesión pausada',
                      style: TextStyle(
                        color: _isKickSessionActive ? Colors.green.shade700 : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$_kicksCount / 10',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: _kicksCount >= 10 ? Colors.teal : Colors.purple.shade700,
                  ),
                ),
                const Text(
                  'Meta Cardiff: 10 patadas en <= 120 min',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (_kicksCount / 10).clamp(0.0, 1.0),
                  backgroundColor: Colors.purple.shade100,
                  color: _kicksCount >= 10 ? Colors.teal : Colors.purple,
                  minHeight: 8,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _recordKick,
                  icon: const Icon(Icons.touch_app, size: 24),
                  label: const Text('+1 Patada Fetal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
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
                      icon: Icon(_isKickSessionActive ? Icons.pause : Icons.play_arrow),
                      label: Text(_isKickSessionActive ? 'Pausar Cronómetro' : 'Iniciar Tiempo'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: (_kicksCount > 0 || _kickElapsedMinutes > 0)
                          ? _saveKickSession
                          : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Live Evaluation Alert
        if (eval.targetReached) ...[
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.teal.shade400),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.teal, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Meta alcanzada! Patrón fetal tranquilizador. 10 movimientos registrados.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (eval.alert != null) ...[
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eval.alert!.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(eval.alert!.message),
                  const SizedBox(height: 8),
                  Text(
                    'Recomendación: ${eval.alert!.actionRecommended}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'Historial de Sesiones de Patadas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return const Text(
                'No hay sesiones de patadas guardadas.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return Column(
              children: sessions.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          s.isReassuring ? Colors.teal.shade100 : Colors.red.shade100,
                      child: Icon(
                        s.isReassuring ? Icons.check : Icons.warning,
                        color: s.isReassuring ? Colors.teal : Colors.red,
                      ),
                    ),
                    title: Text(
                      '${s.kicksCount} patadas en ${s.durationMinutes} min',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${s.isReassuring ? "Patrón tranquilizador" : "Disminución reportada"} • ${s.startedAt.toLocal().toString().substring(0, 16)}',
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
