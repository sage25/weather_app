import 'dart:convert';

import 'package:http/http.dart' as http;

import 'open_meteo_exceptions.dart';
import 'open_meteo_models.dart';

Uri buildOpenMeteoForecastUri({
  required double latitude,
  required double longitude,
}) {
  return Uri.https(
    'api.open-meteo.com',
    '/v1/forecast',
    <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'hourly': 'temperature_2m,weathercode,relative_humidity_2m,apparent_temperature,precipitation,cloudcover',
      'timezone': 'Asia/Shanghai',
      'forecast_days': '2',
    },
  );
}

class OpenMeteoClient {
  OpenMeteoClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<OpenMeteoForecast> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = buildOpenMeteoForecastUri(
      latitude: latitude,
      longitude: longitude,
    );

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on Exception catch (error) {
      throw OpenMeteoNetworkException('网络请求失败：$error');
    }

    if (response.statusCode != 200) {
      throw OpenMeteoNetworkException('接口返回异常：${response.statusCode}');
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OpenMeteoParseException('响应格式不正确');
    }

    final OpenMeteoForecast forecast;
    try {
      forecast = OpenMeteoForecast.fromJson(decoded);
    } on FormatException catch (error) {
      throw OpenMeteoParseException(error.message);
    } catch (error) {
      throw OpenMeteoParseException('解析失败：$error');
    }

    if (forecast.hourly.isEmpty) {
      throw OpenMeteoEmptyDataException('接口没有返回可用天气数据');
    }

    return forecast;
  }

  void dispose() {
    _client.close();
  }
}