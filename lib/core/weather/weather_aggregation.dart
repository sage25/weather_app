import 'dart:math' as math;

import 'open_meteo_models.dart';

class WeatherForecastSummary {
  const WeatherForecastSummary({required this.days});

  final List<WeatherDaySummary> days;
}

class WeatherDaySummary {
  const WeatherDaySummary({
    required this.date,
    required this.dayLabel,
    required this.dateLabel,
    required this.morning,
    required this.afternoon,
    required this.sixHourWindows,
    required this.twoHourWindows,
  });

  final DateTime date;
  final String dayLabel;
  final String dateLabel;
  final WeatherPeriodSummary morning;
  final WeatherPeriodSummary afternoon;
  final List<WeatherPeriodSummary> sixHourWindows;
  final List<WeatherPeriodSummary> twoHourWindows;
}

class WeatherPeriodSummary {
  const WeatherPeriodSummary({
    required this.label,
    required this.summaryText,
    required this.weatherLabel,
    required this.temperatureText,
  });

  final String label;
  final String summaryText;
  final String weatherLabel;
  final String temperatureText;
}

WeatherForecastSummary buildWeatherForecastSummary(OpenMeteoForecast forecast) {
  final List<OpenMeteoHourlySample> samples = List<OpenMeteoHourlySample>.from(forecast.hourly)
    ..sort((OpenMeteoHourlySample left, OpenMeteoHourlySample right) {
      return left.time.compareTo(right.time);
    });

  final List<DateTime> uniqueDays = <DateTime>[];
  for (final OpenMeteoHourlySample sample in samples) {
    final DateTime day = DateTime(sample.time.year, sample.time.month, sample.time.day);
    if (uniqueDays.isEmpty || uniqueDays.last != day) {
      if (!uniqueDays.contains(day)) {
        uniqueDays.add(day);
      }
    }
    if (uniqueDays.length == 2) {
      break;
    }
  }

  final List<WeatherDaySummary> days = <WeatherDaySummary>[];
  for (int index = 0; index < uniqueDays.length; index++) {
    final DateTime day = uniqueDays[index];
    final List<OpenMeteoHourlySample> daySamples = samples
        .where((OpenMeteoHourlySample sample) {
          return _isSameDay(sample.time, day);
        })
        .toList();

    days.add(
      WeatherDaySummary(
        date: day,
        dayLabel: index == 0 ? '今天' : '明天',
        dateLabel: _formatDateLabel(day),
        morning: _buildPeriodSummary(
          label: '上午',
          samples: daySamples.where((OpenMeteoHourlySample sample) => sample.time.hour < 12).toList(),
        ),
        afternoon: _buildPeriodSummary(
          label: '下午',
          samples: daySamples.where((OpenMeteoHourlySample sample) => sample.time.hour >= 12).toList(),
        ),
        sixHourWindows: _buildWindows(
          daySamples,
          windowSizeHours: 6,
        ),
        twoHourWindows: _buildWindows(
          daySamples,
          windowSizeHours: 2,
        ),
      ),
    );
  }

  return WeatherForecastSummary(days: days);
}

List<WeatherPeriodSummary> _buildWindows(
  List<OpenMeteoHourlySample> daySamples, {
  required int windowSizeHours,
}) {
  final List<WeatherPeriodSummary> windows = <WeatherPeriodSummary>[];
  for (int startHour = 0; startHour < 24; startHour += windowSizeHours) {
    final int endHour = startHour + windowSizeHours;
    final List<OpenMeteoHourlySample> windowSamples = daySamples
        .where((OpenMeteoHourlySample sample) {
          return sample.time.hour >= startHour && sample.time.hour < endHour;
        })
        .toList();
    windows.add(
      _buildPeriodSummary(
        label: _formatHourWindowLabel(startHour, endHour),
        samples: windowSamples,
      ),
    );
  }
  return windows;
}

WeatherPeriodSummary _buildPeriodSummary({
  required String label,
  required List<OpenMeteoHourlySample> samples,
}) {
  if (samples.isEmpty) {
    return WeatherPeriodSummary(
      label: label,
      summaryText: '暂无数据',
      weatherLabel: '暂无数据',
      temperatureText: '--',
    );
  }

  final String weatherLabel = _dominantWeatherLabel(samples);
  final String temperatureText = _formatTemperatureText(samples);
  return WeatherPeriodSummary(
    label: label,
    summaryText: '$weatherLabel $temperatureText',
    weatherLabel: weatherLabel,
    temperatureText: temperatureText,
  );
}

String _dominantWeatherLabel(List<OpenMeteoHourlySample> samples) {
  final Map<String, int> counts = <String, int>{};
  final Map<String, int> firstIndex = <String, int>{};
  for (int index = 0; index < samples.length; index++) {
    final String label = weatherCodeToLabel(samples[index].weatherCode);
    counts[label] = (counts[label] ?? 0) + 1;
    firstIndex.putIfAbsent(label, () => index);
  }

  final List<String> labels = counts.keys.toList();
  labels.sort((String left, String right) {
    final int countCompare = (counts[right] ?? 0).compareTo(counts[left] ?? 0);
    if (countCompare != 0) {
      return countCompare;
    }
    return (firstIndex[left] ?? 0).compareTo(firstIndex[right] ?? 0);
  });
  return labels.first;
}

String _formatTemperatureText(List<OpenMeteoHourlySample> samples) {
  final List<double> temperatures = samples.map((OpenMeteoHourlySample sample) => sample.temperature2m).toList();
  final double minTemperature = temperatures.reduce(math.min);
  final double maxTemperature = temperatures.reduce(math.max);
  if ((maxTemperature - minTemperature).abs() < 0.1) {
    return '${minTemperature.round()}℃';
  }
  return '${minTemperature.floor()}-${maxTemperature.ceil()}℃';
}

String _formatHourWindowLabel(int startHour, int endHour) {
  return '${_twoDigits(startHour)}:00-${_twoDigits(endHour)}:00';
}

String _formatDateLabel(DateTime date) {
  return '${date.month}月${date.day}日';
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month && left.day == right.day;
}

String weatherCodeToLabel(int code) {
  switch (code) {
    case 0:
      return '晴';
    case 1:
      return '大部晴';
    case 2:
      return '局部多云';
    case 3:
      return '多云';
    case 45:
    case 48:
      return '有雾';
    case 51:
    case 53:
    case 55:
      return '毛毛雨';
    case 56:
    case 57:
      return '冻毛毛雨';
    case 61:
      return '小雨';
    case 63:
      return '中雨';
    case 65:
      return '大雨';
    case 66:
    case 67:
      return '冻雨';
    case 71:
      return '小雪';
    case 73:
      return '中雪';
    case 75:
      return '大雪';
    case 77:
      return '雪粒';
    case 80:
      return '阵雨';
    case 81:
      return '强阵雨';
    case 82:
      return '暴阵雨';
    case 85:
      return '阵雪';
    case 86:
      return '强阵雪';
    case 95:
      return '雷雨';
    case 96:
    case 99:
      return '雷暴';
    default:
      return '天气';
  }
}