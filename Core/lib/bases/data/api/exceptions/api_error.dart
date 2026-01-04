/// Base API error class.
abstract class ApiError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ApiError(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

