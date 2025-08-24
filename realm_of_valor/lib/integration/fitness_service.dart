abstract class FitnessService {
  Future<int> stepsToday();
  Future<double> distanceTodayKm();
}

class StubFitnessService implements FitnessService {
  @override
  Future<double> distanceTodayKm() async => 0.0;

  @override
  Future<int> stepsToday() async => 0;
}