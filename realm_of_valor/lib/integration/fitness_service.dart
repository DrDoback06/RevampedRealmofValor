import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class FitnessService {
  Future<int> stepsToday();
  Future<double> distanceTodayKm();
  Future<double> caloriesBurnedToday();
  Future<int> heartRate();
  Future<bool> isAvailable();
  Future<void> requestPermissions();
}

class StubFitnessService implements FitnessService {
  bool _isInitialized = false;
  int _mockSteps = 0;
  double _mockDistance = 0.0;
  double _mockCalories = 0.0;
  int _mockHeartRate = 72;

  @override
  Future<bool> isAvailable() async {
    return true; // Always available for web
  }

  @override
  Future<void> requestPermissions() async {
    _isInitialized = true;
    debugPrint('Fitness permissions granted (stub)');
  }

  @override
  Future<int> stepsToday() async {
    if (!_isInitialized) {
      await requestPermissions();
    }

    // Simulate some steps (random walk)
    _mockSteps += (DateTime.now().millisecond % 100);
    debugPrint('Steps today: $_mockSteps');
    return _mockSteps;
  }

  @override
  Future<double> distanceTodayKm() async {
    if (!_isInitialized) {
      await requestPermissions();
    }

    // Convert steps to approximate distance (1 step ≈ 0.0008 km)
    _mockDistance = _mockSteps * 0.0008;
    debugPrint('Distance today: ${_mockDistance.toStringAsFixed(2)} km');
    return _mockDistance;
  }

  @override
  Future<double> caloriesBurnedToday() async {
    if (!_isInitialized) {
      await requestPermissions();
    }

    // Convert steps to approximate calories (1 step ≈ 0.04 calories)
    _mockCalories = _mockSteps * 0.04;
    debugPrint('Calories burned today: ${_mockCalories.toStringAsFixed(1)}');
    return _mockCalories;
  }

  @override
  Future<int> heartRate() async {
    if (!_isInitialized) {
      await requestPermissions();
    }

    // Simulate heart rate variation
    _mockHeartRate = 70 + (DateTime.now().millisecond % 20);
    debugPrint('Heart rate: $_mockHeartRate bpm');
    return _mockHeartRate;
  }
}

// Web-compatible implementations that just use the stub
class HealthKitFitnessService extends StubFitnessService {}
class GoogleFitFitnessService extends StubFitnessService {}
