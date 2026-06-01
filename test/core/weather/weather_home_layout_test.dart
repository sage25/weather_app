import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:weather_app/core/weather/weather_home_layout.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('adapts weather home layout for different screen widths', () {
    final WeatherHomeLayoutSpec narrow = buildWeatherHomeLayoutSpec(const Size(360, 780));
    final WeatherHomeLayoutSpec wide = buildWeatherHomeLayoutSpec(const Size(430, 780));

    expect(narrow.twoHourCrossAxisCount, 2);
    expect(wide.twoHourCrossAxisCount, 3);
    expect(narrow.twoHourLabelWidth, lessThan(wide.twoHourLabelWidth));
    expect(narrow.periodGap, greaterThanOrEqualTo(8));
    expect(wide.pagePadding.horizontal, greaterThanOrEqualTo(narrow.pagePadding.horizontal));
  });

  test('records the first measured layout snapshot only once', () async {
    final WeatherHomeLayoutSpec spec = buildWeatherHomeLayoutSpec(const Size(390, 844));

    await recordWeatherHomeLayoutSpec(spec);
    await recordWeatherHomeLayoutSpec(buildWeatherHomeLayoutSpec(const Size(420, 844)));

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('weather.home.layout.recorded'), isTrue);
    expect(preferences.getString('weather.home.layout.snapshot'), isNotNull);
  });
}