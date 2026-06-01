import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherHomeLayoutSpec {
  const WeatherHomeLayoutSpec({
    required this.screenSize,
    required this.pagePadding,
    required this.pageHeaderGap,
    required this.periodGap,
    required this.periodCardPadding,
    required this.periodCardRadius,
    required this.twoHourSectionGap,
    required this.twoHourGridSpacing,
    required this.twoHourLabelWidth,
    required this.twoHourTemperatureWidth,
    required this.twoHourCrossAxisCount,
  });

  final Size screenSize;
  final EdgeInsets pagePadding;
  final double pageHeaderGap;
  final double periodGap;
  final EdgeInsets periodCardPadding;
  final double periodCardRadius;
  final double twoHourSectionGap;
  final double twoHourGridSpacing;
  final double twoHourLabelWidth;
  final double twoHourTemperatureWidth;
  final int twoHourCrossAxisCount;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'screenWidth': screenSize.width,
      'screenHeight': screenSize.height,
      'pagePaddingLeft': pagePadding.left,
      'pagePaddingTop': pagePadding.top,
      'pagePaddingRight': pagePadding.right,
      'pagePaddingBottom': pagePadding.bottom,
      'pageHeaderGap': pageHeaderGap,
      'periodGap': periodGap,
      'periodCardPaddingHorizontal': periodCardPadding.horizontal / 2,
      'periodCardPaddingVertical': periodCardPadding.vertical / 2,
      'periodCardRadius': periodCardRadius,
      'twoHourSectionGap': twoHourSectionGap,
      'twoHourGridSpacing': twoHourGridSpacing,
      'twoHourLabelWidth': twoHourLabelWidth,
      'twoHourTemperatureWidth': twoHourTemperatureWidth,
      'twoHourCrossAxisCount': twoHourCrossAxisCount,
    };
  }
}

WeatherHomeLayoutSpec buildWeatherHomeLayoutSpec(Size screenSize) {
  final double width = screenSize.width;
  final double height = screenSize.height;

  final double horizontalPadding = _clamp(width * 0.05, 16, 24);
  final double verticalPadding = _clamp(height * 0.03, 14, 22);
  final double pageHeaderGap = _clamp(height * 0.018, 10, 16);
  final double periodGap = _clamp(height * 0.011, 8, 12);
  final double periodCardHorizontal = _clamp(width * 0.04, 14, 18);
  final double periodCardVertical = _clamp(height * 0.014, 10, 14);
  final double periodCardRadius = _clamp(width * 0.05, 16, 20);
  final double twoHourSectionGap = _clamp(height * 0.016, 10, 16);
  final double twoHourGridSpacing = _clamp(width * 0.02, 6, 10);
  final double twoHourLabelWidth = _clamp(width * 0.14, 40, 52);
  final double twoHourTemperatureWidth = _clamp(width * 0.18, 28, 36);
  final int twoHourCrossAxisCount = width < 380 ? 2 : 3;

  return WeatherHomeLayoutSpec(
    screenSize: screenSize,
    pagePadding: EdgeInsets.fromLTRB(
      horizontalPadding,
      verticalPadding,
      horizontalPadding,
      verticalPadding,
    ),
    pageHeaderGap: pageHeaderGap,
    periodGap: periodGap,
    periodCardPadding: EdgeInsets.symmetric(
      horizontal: periodCardHorizontal,
      vertical: periodCardVertical,
    ),
    periodCardRadius: periodCardRadius,
    twoHourSectionGap: twoHourSectionGap,
    twoHourGridSpacing: twoHourGridSpacing,
    twoHourLabelWidth: twoHourLabelWidth,
    twoHourTemperatureWidth: twoHourTemperatureWidth,
    twoHourCrossAxisCount: twoHourCrossAxisCount,
  );
}

Future<void> recordWeatherHomeLayoutSpec(WeatherHomeLayoutSpec spec) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(_recordedKey) == true) {
    return;
  }

  await preferences.setBool(_recordedKey, true);
  await preferences.setString(_layoutKey, jsonEncode(spec.toJson()));
}

const String _recordedKey = 'weather.home.layout.recorded';
const String _layoutKey = 'weather.home.layout.snapshot';

double _clamp(double value, double min, double max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}