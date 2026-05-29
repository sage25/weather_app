import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/core/location/location_validator.dart';

void main() {
  group('location validator', () {
    test('accepts valid latitude and longitude', () {
      expect(latitudeErrorText('29.56'), isNull);
      expect(longitudeErrorText('106.55'), isNull);
    });

    test('rejects invalid latitude and longitude', () {
      expect(latitudeErrorText(''), isNotNull);
      expect(latitudeErrorText('abc'), isNotNull);
      expect(latitudeErrorText('91'), isNotNull);
      expect(longitudeErrorText(''), isNotNull);
      expect(longitudeErrorText('abc'), isNotNull);
      expect(longitudeErrorText('181'), isNotNull);
    });
  });
}