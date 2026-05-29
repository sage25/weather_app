import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:weather_app/core/location/coordinates.dart';
import 'package:weather_app/core/location/location_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('returns null when coordinates are not stored', () async {
    final SharedPreferencesLocationStore store = SharedPreferencesLocationStore();

    expect(await store.read(), isNull);
  });

  test('saves and reads coordinates', () async {
    final SharedPreferencesLocationStore store = SharedPreferencesLocationStore();
    const Coordinates coordinates = Coordinates(latitude: 29.56, longitude: 106.55);

    await store.save(coordinates);

    expect(await store.read(), coordinates);
  });
}