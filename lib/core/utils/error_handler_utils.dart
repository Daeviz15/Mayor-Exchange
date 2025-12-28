import 'dart:async';
import 'dart:io';

class ErrorHandlerUtils {
  /// Returns a user-friendly error message based on the exception type.
  static String getUserFriendlyErrorMessage(Object? error) {
    if (error == null) return 'An unexpected error occurred.';

    // 1. Check for Network Errors (SocketException)
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    // 2. Check for Timeouts
    if (error is TimeoutException) {
      return 'The connection timed out. Please try again later.';
    }

    // 3. Check for HTTP Client Exceptions (Generic "ClientException" often wraps SocketException)
    // Note: To be precise, we check if the string representation contains common keywords
    // if specific types aren't available or if exceptions are wrapped.
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('interaction with the server')) {
      return 'No internet connection. Please check your network.';
    }

    if (errorStr.contains('handshakeexception') ||
        errorStr.contains('certificate')) {
      return 'Secure connection failed. Please check your network time/settings.';
    }

    if (errorStr.contains('404')) {
      return 'Resource not found. Please try again.';
    }

    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return 'Server is currently unavailable. Please try again later.';
    }

    // 4. Default Fallback
    // In production, we might not want to show the raw error at all, but for now
    // simply returning a generic message is better than a stack trace.
    // However, if it's a specific logic error, the original message might be useful if sanitized.
    // For completely unknown errors:
    return 'An unexpected error occurred. Please try again.';
  }
}
