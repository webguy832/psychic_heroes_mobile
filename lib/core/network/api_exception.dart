class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiUnauthorizedException extends ApiException {
  ApiUnauthorizedException([String message = "Your session has expired. Please sign in again.", int? statusCode = 401])
      : super(message, statusCode: statusCode ?? 401);
}
