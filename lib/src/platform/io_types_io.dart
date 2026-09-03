import 'dart:io';

import 'package:dio/dio.dart';

export 'dart:io' show File, HttpException, SocketException;

/// Native Android, iOS, Windows, macOS, and Linux.
const bool hasDartIo = true;

MultipartFile multipartFromFile(File file, {String? filename}) {
  return MultipartFile.fromFileSync(
    file.path,
    filename: filename ?? file.uri.pathSegments.last,
  );
}

Future<MultipartFile> multipartFromPath(String path, {String? filename}) {
  return MultipartFile.fromFile(path, filename: filename);
}
