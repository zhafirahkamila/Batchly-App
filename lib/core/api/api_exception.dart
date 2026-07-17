/// A structured error raised by [ApiClient] whenever the backend responds with
/// a non-2xx status. UI code catches this to show a friendly message.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
