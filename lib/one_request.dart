/// one_request public API.
///
/// Import only this library. HTTP, Either, loading, WebSocket, and
/// connectivity types are available from this file. Add only `one_request`.
///
/// [ResponseType] is one_request's enum (`json` / `bytes` / `stream` / `plain`).
/// The HTTP client's `ResponseType` is hidden to avoid a name clash.
library;

export 'package:dio/dio.dart' hide ResponseType;
export 'package:dart_either/dart_either.dart';
export 'package:flutter_easyloading/flutter_easyloading.dart'
    show
        EasyLoading,
        EasyLoadingIndicatorType,
        EasyLoadingMaskType,
        EasyLoadingStyle;

export 'src/auth/auth_interceptor.dart';
export 'src/connectivity/connectivity_notice_host.dart';
export 'src/connectivity/connectivity_watch.dart';
export 'src/dio_request.dart';
export 'src/model/error.dart';
export 'src/model/request_exception.dart';
export 'src/platform/io_types.dart' show hasDartIo;
export 'src/resolve_url.dart';
export 'src/resourses/types.dart';
export 'src/resourses/utils.dart';
export 'src/socket/one_socket.dart';
