class OpenMeteoException implements Exception {
  OpenMeteoException(this.message);

  final String message;

  @override
  String toString() => 'OpenMeteoException: $message';
}

class OpenMeteoNetworkException extends OpenMeteoException {
  OpenMeteoNetworkException(super.message);
}

class OpenMeteoParseException extends OpenMeteoException {
  OpenMeteoParseException(super.message);
}

class OpenMeteoEmptyDataException extends OpenMeteoException {
  OpenMeteoEmptyDataException(super.message);
}