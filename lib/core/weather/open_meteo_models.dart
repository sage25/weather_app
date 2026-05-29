class OpenMeteoHourlySample {
  const OpenMeteoHourlySample({
    required this.time,
    required this.temperature2m,
    required this.weatherCode,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.cloudCover,
  });

  final DateTime time;
  final double temperature2m;
  final int weatherCode;
  final double? relativeHumidity2m;
  final double? apparentTemperature;
  final double? precipitation;
  final double? cloudCover;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OpenMeteoHourlySample &&
        other.time == time &&
        other.temperature2m == temperature2m &&
        other.weatherCode == weatherCode &&
        other.relativeHumidity2m == relativeHumidity2m &&
        other.apparentTemperature == apparentTemperature &&
        other.precipitation == precipitation &&
        other.cloudCover == cloudCover;
  }

  @override
  int get hashCode => Object.hash(
        time,
        temperature2m,
        weatherCode,
        relativeHumidity2m,
        apparentTemperature,
        precipitation,
        cloudCover,
      );
}

class OpenMeteoForecast {
  const OpenMeteoForecast({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.hourly,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final List<OpenMeteoHourlySample> hourly;

  factory OpenMeteoForecast.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? hourlyJson = json['hourly'] as Map<String, dynamic>?;
    if (hourlyJson == null) {
      throw FormatException('Missing hourly data');
    }

    final List<dynamic>? times = hourlyJson['time'] as List<dynamic>?;
    final List<dynamic>? temperatures = hourlyJson['temperature_2m'] as List<dynamic>?;
    final List<dynamic>? weatherCodes = hourlyJson['weathercode'] as List<dynamic>?;
    final List<dynamic>? humidity = hourlyJson['relative_humidity_2m'] as List<dynamic>?;
    final List<dynamic>? apparentTemperatures = hourlyJson['apparent_temperature'] as List<dynamic>?;
    final List<dynamic>? precipitation = hourlyJson['precipitation'] as List<dynamic>?;
    final List<dynamic>? cloudCover = hourlyJson['cloudcover'] as List<dynamic>?;

    if (times == null || temperatures == null || weatherCodes == null) {
      throw FormatException('Missing hourly weather fields');
    }

    final int length = times.length;
    if (length == 0) {
      return OpenMeteoForecast(
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        timezone: json['timezone'] as String? ?? 'Asia/Shanghai',
        hourly: <OpenMeteoHourlySample>[],
      );
    }

    if (temperatures.length != length || weatherCodes.length != length) {
      throw FormatException('Hourly fields have different lengths');
    }

    final List<OpenMeteoHourlySample> samples = <OpenMeteoHourlySample>[];
    for (int index = 0; index < length; index++) {
      final DateTime time = DateTime.parse(times[index].toString());
      samples.add(
        OpenMeteoHourlySample(
          time: time,
          temperature2m: (temperatures[index] as num).toDouble(),
          weatherCode: (weatherCodes[index] as num).toInt(),
          relativeHumidity2m: _readNullableDouble(humidity, index),
          apparentTemperature: _readNullableDouble(apparentTemperatures, index),
          precipitation: _readNullableDouble(precipitation, index),
          cloudCover: _readNullableDouble(cloudCover, index),
        ),
      );
    }

    return OpenMeteoForecast(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      timezone: json['timezone'] as String? ?? 'Asia/Shanghai',
      hourly: samples,
    );
  }

  static double? _readNullableDouble(List<dynamic>? values, int index) {
    if (values == null || index >= values.length || values[index] == null) {
      return null;
    }
    return (values[index] as num).toDouble();
  }
}