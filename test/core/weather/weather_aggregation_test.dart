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
    expect(summary.days.first.dawn.summaryText, '多云 10-15℃');
    expect(summary.days.first.morning.summaryText, '多云 16-21℃');
    expect(summary.days.first.afternoon.summaryText, '晴 22-27℃');
    expect(summary.days.first.evening.summaryText, '晴 28-33℃');
    expect(summary.days.first.twoHourWindows, hasLength(12));
    expect(summary.days.first.twoHourWindows.first.label, '00~02');
    expect(summary.days.first.twoHourWindows.first.temperatureText, '11');
    expect(summary.days.first.twoHourWindows.first.summaryText, '多云 11');
    expect(summary.days.first.twoHourWindows[11].label, '22~24');
    expect(summary.days.first.twoHourWindows[11].temperatureText, '33');
    expect(summary.days.first.twoHourWindows[11].summaryText, '晴 33');
  });

  test('maps weather codes to readable Chinese labels', () {
    expect(weatherCodeToLabel(0), '晴');
    expect(weatherCodeToLabel(3), '多云');
    expect(weatherCodeToLabel(63), '中雨');
    expect(weatherCodeToLabel(99), '雷暴');
  });
}