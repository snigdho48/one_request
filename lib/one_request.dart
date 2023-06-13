// ignore_for_file: camel_case_types

library one_request;

import 'package:flutter/material.dart';
import 'src/resourses/utils.dart';
import 'src/dio_request.dart';

class oneRequest extends basehttpRequest {
  static get initLoading => LoadingStuff.initLoading;
  static get loading => LoadingStuff.loading;
  // @override
  // Future<Either<dynamic, CustomExceptionHandlers>> send({
  //   Map<String, dynamic>? body,
  //   Map<String, dynamic>? queryParameters,
  //   bool formData = false,
  //   String? responsetype = 'json',
  //   required String url,
  //   required String method,
  //   Map<String, String>? header,
  //   int? maxRedirects = 1,
  //   String contentType = 'application/json',
  //   int timeout = 60,
  //   bool innderData = false,
  // }) {
  //   return super.send(
  //     body: body,
  //     queryParameters: queryParameters,
  //     formData: formData,
  //     responsetype: responsetype,
  //     url: url,
  //     method: method,
  //     header: header,
  //     maxRedirects: maxRedirects,
  //     contentType: contentType,
  //     timeout: timeout,
  //     innderData: innderData,
  //   );
  // }

  static loadingWidget({
    String? status,
    Color? color,
    Widget? indicator,
  }) =>
      LoadingStuff.loading(
        status: status,
        color: color,
        indicator: indicator,
      );
  static loadingconfig({
    Widget? indicator,
    Color? progressColor,
    Color? backgroundColor,
    Color? indicatorColor,
    Color? textColor,
    Widget? success,
    Widget? error,
    Widget? info,
  }) =>
      LoadingStuff.configLoading(
        indicator: indicator,
        progressColor: progressColor,
        backgroundColor: backgroundColor,
        indicatorColor: indicatorColor,
        textColor: textColor,
        success: success,
        error: error,
        info: info,
      );

  //return result of request
}
