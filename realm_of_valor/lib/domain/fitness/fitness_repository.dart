abstract class FitnessRepository {
  Stream<int> stepsToday();
}

class DummyFitnessRepository implements FitnessRepository {
  @override
  Stream<int> stepsToday() async* {
    yield 0;
  }
}