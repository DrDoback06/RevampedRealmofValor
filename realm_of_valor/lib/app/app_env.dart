class AppEnv {
  static const mapsKey = String.fromEnvironment('MAPS_KEY');
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
}
