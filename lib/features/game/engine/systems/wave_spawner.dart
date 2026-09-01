import 'package:flame/components.dart';

import '../../domain/models/level.dart';

enum _Phase { countdown, spawning, done }

/// Reads a list of [WaveData] and releases enemies over time.
///
/// The spawner only knows *when* to spawn; it calls [onSpawnEnemy] and lets the
/// game create the actual component. That keeps this class free of game/render
/// state and unit-testable by pumping [update].
class WaveSpawner extends Component {
  WaveSpawner({
    required this.waves,
    required this.timeBetweenWaves,
    required this.onSpawnEnemy,
    this.onWaveStart,
  }) : assert(waves.isNotEmpty, 'need at least one wave') {
    _countdown = timeBetweenWaves;
  }

  final List<WaveData> waves;
  final double timeBetweenWaves;

  /// Called once per enemy that should appear at the path start.
  final void Function() onSpawnEnemy;

  /// Called with the 1-based wave number when a wave begins spawning.
  final void Function(int waveNumber)? onWaveStart;

  _Phase _phase = _Phase.countdown;
  int _waveIndex = -1;
  double _countdown = 0;
  double _spawnTimer = 0;

  /// Remaining spawn delays for the wave currently spawning. The first entry is
  /// the delay until the next enemy.
  final List<double> _pending = <double>[];

  /// 1-based number of the current (or most recently started) wave; 0 before the
  /// first wave begins.
  int get currentWaveNumber => _waveIndex + 1;

  int get totalWaves => waves.length;

  /// True once every enemy of every wave has been handed to [onSpawnEnemy].
  bool get allWavesSpawned => _phase == _Phase.done;

  /// True while counting down to a wave that has not started yet.
  bool get canCallNextWave =>
      _phase == _Phase.countdown && _waveIndex + 1 < waves.length;

  /// Seconds until the next wave auto-starts (0 when not counting down).
  double get timeUntilNextWave =>
      _phase == _Phase.countdown ? (_countdown < 0 ? 0 : _countdown) : 0;

  int get pendingInCurrentWave => _pending.length;

  /// Pull the next wave immediately, skipping the remaining countdown.
  void callNextWaveEarly() {
    if (canCallNextWave) {
      _countdown = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (_phase) {
      case _Phase.countdown:
        _countdown -= dt;
        if (_countdown <= 0) {
          _startNextWave();
        }
      case _Phase.spawning:
        _spawnTimer -= dt;
        while (_pending.isNotEmpty && _spawnTimer <= 0) {
          onSpawnEnemy();
          _pending.removeAt(0);
          if (_pending.isNotEmpty) {
            _spawnTimer += _pending.first;
          }
        }
        if (_pending.isEmpty) {
          if (_waveIndex + 1 < waves.length) {
            _phase = _Phase.countdown;
            _countdown = timeBetweenWaves;
          } else {
            _phase = _Phase.done;
          }
        }
      case _Phase.done:
        break;
    }
  }

  void _startNextWave() {
    _waveIndex++;
    _phase = _Phase.spawning;
    _pending.clear();
    var first = true;
    for (final group in waves[_waveIndex].groups) {
      for (var i = 0; i < group.count; i++) {
        _pending.add(first ? 0.0 : group.interval);
        first = false;
      }
    }
    _spawnTimer = 0;
    onWaveStart?.call(_waveIndex + 1);
    if (_pending.isEmpty) {
      // Degenerate empty wave — advance immediately.
      if (_waveIndex + 1 < waves.length) {
        _phase = _Phase.countdown;
        _countdown = timeBetweenWaves;
      } else {
        _phase = _Phase.done;
      }
    }
  }
}
