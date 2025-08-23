abstract class MapRepository {
  Future<void> preloadTiles();
}

class DummyMapRepository implements MapRepository {
  @override
  Future<void> preloadTiles() async {}
}