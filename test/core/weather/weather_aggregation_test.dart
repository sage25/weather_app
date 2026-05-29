import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/core/weather/open_meteo_models.dart';
import 'package:weather_app/core/weather/weather_aggregation.dart';

OpenMeteoForecast _buildForecast() {
  final List<OpenMeteoHourlySample> samples = <OpenMeteoHourlySample>[];
  for (int hour = 0; hour < 24; hour++) {
    samples.add(
      OpenMeteoHourlySample(
        time: DateTime(2026, 5, 29, hour),
        temperature2m: 10.0 + hour,
        weatherCode: hour < 12 ? 3 : 0,
        relativeHumidity2m: null,
        apparentTemperature: null,
        precipitation: null,
        cloudCover: null,
      ),
    );
  }

  for (int hour = 0; hour < 24; hour++) {
    samples.add(
      OpenMeteoHourlySample(
        time: DateTime(2026, 5, 30, hour),
        temperature2m: 20.0 + hour,
        weatherCode: hour < 12 ? 2 : 1,
        relativeHumidity2m: null,
        apparentTemperature: null,
        precipitation: null,
        cloudCover: null,
      ),
    );
  }

  return OpenMeteoForecast(
    latitude: 29.56,
    longitude: 106.55,
    timezone: 'Asia/Shanghai',
    hourly: samples,
  );
}

void main() {
  test('builds today and tomorrow summaries with fixed windows', () {
    final WeatherForecastSummary summary = buildWeatherForecastSummary(_buildForecast());

    expect(summary.days, hasLength(2));
    expect(summary.days.first.dayLabel, '今天');
    expect(summary.days.last.dayLabel, '明天');
    expect(summary.days.first.sixHourWindows, hasLength(4));
    expect(summary.days.first.twoHourWindows, hasLength(12));
    expect(summary.days.first.morning.summaryText, '多云 10-21℃');
    expect(summary.days.first.afternoon.summaryText, '晴 22-33℃');
  });

  test('maps weather codes to readable Chinese labels', () {
    expect(weatherCodeToLabel(0), '晴');
    expect(weatherCodeToLabel(3), '多云');
    expect(weatherCodeToLabel(63), '中雨');
    expect(weatherCodeToLabel(99), '雷暴');
  });
}