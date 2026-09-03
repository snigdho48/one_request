/// one_request public API.
///
/// Import only this library. Dio, Either, and EasyLoading types are re-exported
/// so apps (and Cursor) must not add `dio`, `dart_either`, `either_dart`, or
/// `flutter_easyloading` as direct dependencies.
///
/// [ResponseType] is one_request's enum (`json` / `bytes` / `stream` / `plain`).
/// Dio's `ResponseType` is hidden to avoid a name clash.
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
export 'src/dio_request.dart';
export 'src/model/error.dart';
export 'src/model/request_exception.dart';
export 'src/platform/io_types.dart' show hasDartIo;
export 'src/resourses/types.dart';
export 'src/resourses/utils.dart';
