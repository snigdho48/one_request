import 'package:dio/dio.dart';

// Web / WASM stubs. No dart:io — path uploads are not available.

class File {
  File(this.path);
  final String path;
}

class SocketException implements Exception {
  SocketException([this.message = '']);
  final String message;
}

class HttpException implements Exception {
  HttpException([this.message = '']);
  final String message;
}

const bool hasDartIo = false;

Never _unsupported(String api) => throw UnsupportedError(
      '$api is not available on web. Use fileFromByte or fileFormString.',
    );

MultipartFile multipartFromFile(File file, {String? filename}) =>
    _unsupported('file()');

Future<MultipartFile> multipartFromPath(String path,
        {String? filename}) async =>
    _unsupported('fileFromPath()');
