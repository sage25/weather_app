import 'coordinates.dart';

double? validateLatitude(String input) {
  final double? value = double.tryParse(input.trim());
  if (value == null) {
    return null;
  }
  if (value < -90 || value > 90) {
    return null;
  }
  return value;
}

double? validateLongitude(String input) {
  final double? value = double.tryParse(input.trim());
  if (value == null) {
    return null;
  }
  if (value < -180 || value > 180) {
    return null;
  }
  return value;
}

String? latitudeErrorText(String? input) {
  final String trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '请输入纬度';
  }
  final double? value = double.tryParse(trimmed);
  if (value == null) {
    return '纬度必须是数字';
  }
  if (value < -90 || value > 90) {
    return '纬度范围是 -90 到 90';
  }
  return null;
}

String? longitudeErrorText(String? input) {
  final String trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '请输入经度';
  }
  final double? value = double.tryParse(trimmed);
  if (value == null) {
    return '经度必须是数字';
  }
  if (value < -180 || value > 180) {
    return '经度范围是 -180 到 180';
  }
  return null;
}

Coordinates? parseCoordinates(String latitudeInput, String longitudeInput) {
  final double? latitude = validateLatitude(latitudeInput);
  final double? longitude = validateLongitude(longitudeInput);
  if (latitude == null || longitude == null) {
    return null;
  }
  return Coordinates(latitude: latitude, longitude: longitude);
}