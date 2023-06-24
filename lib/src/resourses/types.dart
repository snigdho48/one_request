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
extension ParseRequestType on RequestType {
  //[RequestType.value] is used to specify the type of request expected from the server.
  String get value {
    switch (this) {
      // [RequestType.GET] is used to specify the type of request expected from the server.
      case RequestType.GET:
        return 'GET';
      // [RequestType.POST] is used to specify the type of request expected from the server.
      case RequestType.POST:
        return 'POST';
      // [RequestType.PUT] is used to specify the type of request expected from the server.
      case RequestType.PUT:
        return 'PUT';
      // [RequestType.DELETE] is used to specify the type of request expected from the server.
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
extension ParseResponseType on ResponseType {
  //[ResponseType.value] is used to specify the type of response expected from the server.
  dio.ResponseType get value {
    switch (this) {
      // [ResponseType.json] is used to specify the type of response expected from the server.
      case ResponseType.json:
        return dio.ResponseType.json;
      //[ResponseType.bytes] is used to specify the type of response expected from the server.
      case ResponseType.bytes:
        return dio.ResponseType.bytes;
      //[ResponseType.stream] is used to specify the type of response expected from the server.
      case ResponseType.stream:
        return dio.ResponseType.stream;
      //[ResponseType.plain] is used to specify the type of response expected from the server.
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
extension ParseContentType on ContentType {
  // ignore: avoid_returning_null
  String get value {
    switch (this) {
      // [ContentType.json] is used to specify the type of content expected from the server.
      case ContentType.json:
        return 'application/json';
      // [ContentType.stream] is used to specify the type of content expected from the server.
      case ContentType.stream:
        return 'application/octet-stream';
      //[ContentType.bytes] is used to specify the type of content expected from the server.
      case ContentType.bytes:
        return 'application/octet-stream';
      //[ContentType.text] is used to specify the type of content expected from the server.
      case ContentType.text:
        return 'text/plain';
      default:
        return 'application/json';
    }
  }
}
