import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:weather_app/core/weather/open_meteo_client.dart';
import 'package:weather_app/core/weather/open_meteo_exceptions.dart';
import 'package:weather_app/core/weather/open_meteo_models.dart';

void main() {
  test('builds the expected forecast URL', () {
    final Uri uri = buildOpenMeteoForecastUri(latitude: 29.56, longitude: 106.55);

    expect(uri.scheme, 'https');
    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    expect(uri.queryParameters['latitude'], '29.56');
    expect(uri.queryParameters['longitude'], '106.55');
    expect(uri.queryParameters['timezone'], 'Asia/Shanghai');
    expect(uri.queryParameters['forecast_days'], '2');
  });

  test('parses a valid forecast payload', () {
    const Map<String, Object?> payload = <String, Object?>{
      'latitude': 29.56,
      'longitude': 106.55,
      'timezone': 'Asia/Shanghai',
      'hourly': <String, Object?>{
        'time': <String>[
          '2026-05-29T00:00',
          '2026-05-29T01:00',
        ],
        'temperature_2m': <num>[18.0, 19.0],
        'weathercode': <num>[1, 2],
        'relative_humidity_2m': <num>[40, 42],
        'apparent_temperature': <num>[17.0, 18.0],
        'precipitation': <num>[0, 0.1],
        'cloudcover': <num>[10, 20],
      },
    };

    final OpenMeteoForecast forecast = OpenMeteoForecast.fromJson(
      jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
    );

    expect(forecast.latitude, 29.56);
    expect(forecast.longitude, 106.55);
    expect(forecast.timezone, 'Asia/Shanghai');
    expect(forecast.hourly, hasLength(2));
    expect(forecast.hourly.first.temperature2m, 18.0);
    expect(forecast.hourly.first.weatherCode, 1);
  });

  test('throws empty data error when the API returns no hourly samples', () async {
    final OpenMeteoClient client = OpenMeteoClient(
      client: MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'latitude': 29.56,
            'longitude': 106.55,
            'timezone': 'Asia/Shanghai',
            'hourly': <String, Object?>{
              'time': <String>[],
              'temperature_2m': <num>[],
              'weathercode': <num>[],
            },
          }),
          200,
        );
      }),
    );

    expect(
      () => client.fetchForecast(latitude: 29.56, longitude: 106.55),
      throwsA(isA<OpenMeteoEmptyDataException>()),
    );
  });

  test('wraps network failures in a network exception', () async {
    final OpenMeteoClient client = OpenMeteoClient(
      client: MockClient((http.Request request) async {
        throw Exception('offline');
      }),
    );

    expect(
      () => client.fetchForecast(latitude: 29.56, longitude: 106.55),
      throwsA(isA<OpenMeteoNetworkException>()),
    );
  });
}