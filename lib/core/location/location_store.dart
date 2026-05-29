import 'package:shared_preferences/shared_preferences.dart';

import 'coordinates.dart';

abstract class LocationStore {
  Future<Coordinates?> read();

  Future<void> save(Coordinates coordinates);

  Future<void> clear();
}

class SharedPreferencesLocationStore implements LocationStore {
  static const String _latitudeKey = 'weather.latitude';
  static const String _longitudeKey = 'weather.longitude';

  @override
  Future<Coordinates?> read() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final double? latitude = preferences.getDouble(_latitudeKey);
    final double? longitude = preferences.getDouble(_longitudeKey);

    if (latitude == null || longitude == null) {
      return null;
    }

    return Coordinates(latitude: latitude, longitude: longitude);
  }

  @override
  Future<void> save(Coordinates coordinates) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_latitudeKey, coordinates.latitude);
    await preferences.setDouble(_longitudeKey, coordinates.longitude);
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_latitudeKey);
    await preferences.remove(_longitudeKey);
  }
}