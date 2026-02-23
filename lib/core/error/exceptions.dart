class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'No Internet Connection']);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server Error', super.code]);
}

class CacheException extends AppException {
  CacheException([super.message = 'Cache Error']);
}

class AuthException extends AppException {
  AuthException([super.message = 'Authentication Error', super.code]);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}
