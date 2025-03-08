import 'dart:async';
import 'dart:io';

/// An exception class for handling application-specific errors.
///
/// This class implements the [Exception] interface and can be used to throw and catch exceptions.
///
/// The [message] parameter can be used to provide a custom error message.
/// The [prefix] parameter can be used to add a prefix to the error message.
/// The [url] parameter can be used to provide the URL where the error occurred.
class AppException implements Exception {
  final String? message;
  final String? prefix;
  final String? url;

  AppException([this.message, this.prefix, this.url]);
}

/// Exception thrown for 400 Bad Request HTTP error.
/// Exception thrown when there is an error processing an API request due to a bad request.
class BadRequestException extends AppException {
  BadRequestException([String? message, String? url])
      : super(message, 'Bad request', url);
}

/// Exception thrown when there is an error fetching data from an API.
class FetchDataException extends AppException {
  FetchDataException([String? message, String? url])
      : super(message, 'Unable to process the request', url);
}

/// Exception thrown when the API does not respond.
class ApiNotRespondingException extends AppException {
  ApiNotRespondingException([String? message, String? url])
      : super(message, 'Api not responding', url);
}

/// Exception thrown when the API request is unauthorized.
class UnAuthorizedException extends AppException {
  UnAuthorizedException([String? message, String? url])
      : super(message, 'Unauthorized request', url);
}

/// Exception thrown when the requested page is not found.
class NotFoundException extends AppException {
  NotFoundException([String? message, String? url])
      : super(message, 'Page not found', url);
}

class CustomExceptionHandlers {
  dynamic error;

  /// Creates an instance of [CustomExceptionHandlers] with the given [error].
  CustomExceptionHandlers({required this.error});

  /// Returns a string message based on the type of exception passed to it.
  ///
  /// If the exception type is not recognized, it returns 'Unknown error occured.'.
  /// Returns a string representation of the error.
  ///
  /// If the error is a [SocketException], the method returns 'No internet connection.'.
  /// If the error is an [HttpException], the method returns 'HTTP error occured.'.
  /// If the error is a [FormatException], the method returns 'Invalid data format.'.
  /// If the error is a [TimeoutException], the method returns 'Request timedout.'.
  /// If the error is a [BadRequestException], the method returns the error message as a string.
  /// If the error is an [UnAuthorizedException], the method returns the error message as a string.
  /// If the error is a [NotFoundException], the method returns the error message as a string.
  /// If the error is a [FetchDataException], the method returns the error message as a string.
  /// If the error is of any other type, the method returns 'Unknown error occured.'.
  getExceptionString() {
    if (error is SocketException) {
      return 'No internet connection.';
    } else if (error is HttpException) {
      return 'HTTP error occured.';
    } else if (error is FormatException) {
      return 'Invalid data format.';
    } else if (error is TimeoutException) {
      return 'Request timedout.';
    } else if (error is BadRequestException) {
      return error.message.toString();
    } else if (error is UnAuthorizedException) {
      return error.message.toString();
    } else if (error is NotFoundException) {
      return error.message.toString();
    } else if (error is FetchDataException) {
      return error.message.toString();
    } else {
      return error.toString();
    }
  }
}
