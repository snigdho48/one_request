import 'package:dio/dio.dart' as dio;

// [RequestType] is used to specify the type of request expected from the server.
enum RequestType {
  // ignore: constant_identifier_names
  GET,
  // ignore: constant_identifier_names
  POST,
  // ignore: constant_identifier_names
  PUT,
  // ignore: constant_identifier_names
  DELETE,
}

// [RequestTypes] is used to specify the type of request expected from the server.
/// Extension method to parse [RequestType] to a [String] value.
///
/// This extension method is used to specify the type of request expected from the server.
///
/// Example usage:
/// ```dart
/// RequestType requestType = RequestType.GET;
/// String requestTypeValue = requestType.value; // returns 'GET'
/// ```
extension ParseRequestType on RequestType {
  /// Returns the [String] value of the [RequestType].
  ///
  /// The [RequestType] can be one of the following:
  /// - [RequestType.GET]
  /// - [RequestType.POST]
  /// - [RequestType.PUT]
  /// - [RequestType.DELETE]
  ///
  /// If the [RequestType] is not one of the above, it returns 'GET' by default.
  String get value {
    switch (this) {
      case RequestType.GET:
        return 'GET';
      case RequestType.POST:
        return 'POST';
      case RequestType.PUT:
        return 'PUT';
      case RequestType.DELETE:
        return 'DELETE';
      default:
        return 'GET';
    }
  }
}

// [ResponseType] is used to specify the type of response expected from the server.
enum ResponseType {
  //[ResponseType.json]
  json,
  //[ResponseType.bytes]
  bytes,
  //[ResponseType.stream]
  stream,
  //[ResponseType.plain]
  plain,
}

// [ResponseTypes] is used to specify the type of response expected from the server.
/// An extension on [ResponseType] enum to convert it to [dio.ResponseType].
extension ParseResponseType on ResponseType {
  /// Returns the [dio.ResponseType] equivalent of the [ResponseType] enum.
  ///
  /// [ResponseType.value] is used to specify the type of response expected from the server.
  ///
  /// [ResponseType.json] is used to specify the type of response expected from the server.
  ///
  /// [ResponseType.bytes] is used to specify the type of response expected from the server.
  ///
  /// [ResponseType.stream] is used to specify the type of response expected from the server.
  ///
  /// [ResponseType.plain] is used to specify the type of response expected from the server.
  ///
  /// If the [ResponseType] is not one of the above, it returns [dio.ResponseType.json] as default.
  dio.ResponseType get value {
    switch (this) {
      case ResponseType.json:
        return dio.ResponseType.json;
      case ResponseType.bytes:
        return dio.ResponseType.bytes;
      case ResponseType.stream:
        return dio.ResponseType.stream;
      case ResponseType.plain:
        return dio.ResponseType.plain;
      default:
        return dio.ResponseType.json;
    }
  }
}

// [ContentType] is used to specify the type of content expected from the server.
enum ContentType {
  //[ContentType.json]
  json,
  //[ContentType.stream]
  stream,
  //[ContentType.bytes]
  bytes,
  //[ContentType.text]
  text,
}

// [ContentTypes] is used to specify the type of content expected from the server.
/// An extension on [ContentType] that provides a [value] getter to return the corresponding MIME type string for the content type.
extension ParseContentType on ContentType {
  /// Returns the corresponding MIME type string for the content type.
  ///
  /// - [ContentType.json] is mapped to 'application/json'.
  /// - [ContentType.stream] is mapped to 'application/octet-stream'.
  /// - [ContentType.bytes] is mapped to 'application/octet-stream'.
  /// - [ContentType.text] is mapped to 'text/plain'.
  ///
  /// If the content type is not one of the above, it defaults to 'application/json'.
  String get value {
    switch (this) {
      case ContentType.json:
        return 'application/json';
      case ContentType.stream:
        return 'application/octet-stream';
      case ContentType.bytes:
        return 'application/octet-stream';
      case ContentType.text:
        return 'text/plain';
      default:
        return 'application/json';
    }
  }
}
