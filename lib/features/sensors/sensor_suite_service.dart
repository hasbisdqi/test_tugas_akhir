import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  SensorData({
    required this.x,
    required this.y,
    required this.z,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  double get magnitude => sqrt(x * x + y * y + z * z);
}

class SensorSuiteService {
  static final SensorSuiteService _instance = SensorSuiteService._internal();
  factory SensorSuiteService() => _instance;
  SensorSuiteService._internal();

  bool isSimulated = false;
  Timer? _simulationTimer;

  final _accelController = StreamController<SensorData>.broadcast();
  final _gyroController = StreamController<SensorData>.broadcast();

  Stream<SensorData> get accelerometerStream => _accelController.stream;
  Stream<SensorData> get gyroscopeStream => _gyroController.stream;

  StreamSubscription? _rawAccelSub;
  StreamSubscription? _rawGyroSub;

  double _simAngle = 0.0;

  void startListening() {
    try {
      _rawAccelSub = accelerometerEventStream().listen(
        (event) {
          isSimulated = false;
          _accelController.add(SensorData(x: event.x, y: event.y, z: event.z));
        },
        onError: (err) {
          _enableSimulation();
        },
        cancelOnError: false,
      );

      _rawGyroSub = gyroscopeEventStream().listen(
        (event) {
          isSimulated = false;
          _gyroController.add(SensorData(x: event.x, y: event.y, z: event.z));
        },
        onError: (err) {
          _enableSimulation();
        },
        cancelOnError: false,
      );

      // Timeout fallback: If no hardware event received within 1.5 seconds, start simulation fallback
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!_accelController.hasListener && !_gyroController.hasListener) return;
        if (!isSimulated && _rawAccelSub == null) {
          _enableSimulation();
        }
      });
    } catch (e) {
      _enableSimulation();
    }
  }

  void _enableSimulation() {
    if (isSimulated && _simulationTimer != null && _simulationTimer!.isActive) return;
    isSimulated = true;

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _simAngle += 0.08;
      final noise = (Random().nextDouble() - 0.5) * 0.2;

      // Realistic tilt simulator (e.g. slight device wobble)
      final ax = sin(_simAngle) * 3.5 + noise;
      final ay = cos(_simAngle * 0.7) * 4.2;
      final az = 9.8 - (ax.abs() + ay.abs()) * 0.15;

      _accelController.add(SensorData(x: ax, y: ay, z: az));

      // Realistic gyroscope simulator (rotation rate in rad/s)
      final gx = cos(_simAngle) * 0.5 + noise * 0.1;
      final gy = -sin(_simAngle * 0.7) * 0.4;
      final gz = 0.1 * sin(_simAngle * 1.5);

      _gyroController.add(SensorData(x: gx, y: gy, z: gz));
    });
  }

  void stopListening() {
    _rawAccelSub?.cancel();
    _rawGyroSub?.cancel();
    _rawAccelSub = null;
    _rawGyroSub = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void dispose() {
    stopListening();
    _accelController.close();
    _gyroController.close();
  }
}
