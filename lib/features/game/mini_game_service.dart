import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum GameItemType {
  goldenPaddy, // +50 pts
  freshChili,  // +30 pts
  organicCoffee,// +20 pts
  pestBug,     // -40 pts (penalty)
  cryptoSolana,// +100 bonus pts
}

class HarvestTarget {
  final String id;
  final GameItemType type;
  final double x; // normalized 0.0 - 1.0
  final double y; // normalized 0.0 - 1.0
  final int points;
  final String emoji;
  final String label;
  final DateTime spawnTime;

  HarvestTarget({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.points,
    required this.emoji,
    required this.label,
    DateTime? spawnTime,
  }) : spawnTime = spawnTime ?? DateTime.now();
}

class MiniGameService {
  static const String highScoreKey = 'mini_game_harvest_high_score';
  static final MiniGameService _instance = MiniGameService._internal();
  factory MiniGameService() => _instance;
  MiniGameService._internal();

  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 30; // 30-second reflex round
  bool _isPlaying = false;
  final List<HarvestTarget> _activeTargets = [];

  int get score => _score;
  int get highScore => _highScore;
  int get timeLeft => _timeLeft;
  bool get isPlaying => _isPlaying;
  List<HarvestTarget> get activeTargets => List.unmodifiable(_activeTargets);

  Timer? _gameTimer;
  Timer? _spawnerTimer;
  Function()? onStateChanged;

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(highScoreKey) ?? 0;
  }

  Future<void> _saveHighScore(int newHigh) async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = newHigh;
    await prefs.setInt(highScoreKey, newHigh);
  }

  void startGame({Function()? onUpdate}) {
    _score = 0;
    _timeLeft = 30;
    _isPlaying = true;
    _activeTargets.clear();
    onStateChanged = onUpdate;

    _gameTimer?.cancel();
    _spawnerTimer?.cancel();

    // 1-second interval countdown
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        onStateChanged?.call();
      } else {
        endGame();
      }
    });

    // Spawner loop: creates randomized harvest items every 600ms
    _spawnerTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      _spawnRandomTarget();
      onStateChanged?.call();
    });

    onStateChanged?.call();
  }

  void _spawnRandomTarget() {
    // Keep max 5 targets active at a time
    if (_activeTargets.length >= 5) {
      _activeTargets.removeAt(0);
    }

    final rand = Random();
    final itemRoll = rand.nextDouble();
    GameItemType type;
    int points;
    String emoji;
    String label;

    if (itemRoll < 0.10) {
      type = GameItemType.cryptoSolana;
      points = 100;
      emoji = '💎';
      label = 'Solana Gem (+100)';
    } else if (itemRoll < 0.28) {
      type = GameItemType.pestBug;
      points = -40;
      emoji = '🐛';
      label = 'Crop Pest (-40)';
    } else if (itemRoll < 0.55) {
      type = GameItemType.goldenPaddy;
      points = 50;
      emoji = '🌾';
      label = 'Golden Paddy (+50)';
    } else if (itemRoll < 0.80) {
      type = GameItemType.freshChili;
      points = 30;
      emoji = '🌶️';
      label = 'Fresh Chili (+30)';
    } else {
      type = GameItemType.organicCoffee;
      points = 20;
      emoji = '☕';
      label = 'Coffee Bean (+20)';
    }

    final target = HarvestTarget(
      id: 'tgt-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      x: 0.1 + rand.nextDouble() * 0.75,
      y: 0.1 + rand.nextDouble() * 0.75,
      points: points,
      emoji: emoji,
      label: label,
    );

    _activeTargets.add(target);
  }

  /// User taps a target
  int tapTarget(String targetId) {
    final index = _activeTargets.indexWhere((t) => t.id == targetId);
    if (index == -1 || !_isPlaying) return 0;

    final target = _activeTargets.removeAt(index);
    _score += target.points;
    if (_score < 0) _score = 0; // Don't let score drop below 0

    if (_score > _highScore) {
      _saveHighScore(_score);
    }

    onStateChanged?.call();
    return target.points;
  }

  void endGame() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _spawnerTimer?.cancel();
    _activeTargets.clear();

    if (_score > _highScore) {
      _saveHighScore(_score);
    }
    onStateChanged?.call();
  }

  void dispose() {
    _gameTimer?.cancel();
    _spawnerTimer?.cancel();
  }
}
