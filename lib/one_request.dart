// ignore_for_file: camel_case_types

library one_request;

import 'package:flutter/material.dart';
import 'src/resourses/utils.dart';
import 'src/dio_request.dart';

class oneRequest extends basehttpRequest {
  static get initLoading => LoadingStuff.initLoading;
  static get loading => LoadingStuff.loading;

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
      LoadingStuff.configLoad(
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
