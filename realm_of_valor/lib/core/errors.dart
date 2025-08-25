abstract class AppError {
  String get message;
}

class NetworkError implements AppError {
  NetworkError([this._message = 'Network error']);
  final String _message;
  @override
  String get message => _message;
}

class AuthError implements AppError {
  AuthError([this._message = 'Authentication error']);
  final String _message;
  @override
  String get message => _message;
}

class NotFoundError implements AppError {
  NotFoundError([this._message = 'Not found']);
  final String _message;
  @override
  String get message => _message;
}

class ValidationError implements AppError {
  ValidationError([this._message = 'Validation error']);
  final String _message;
  @override
  String get message => _message;
}

