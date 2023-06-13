library one_request;

import 'package:flutter/material.dart';

import 'src/dio_request.dart';

class oneRequest extends basehttpRequest {
  static Function({
    String? status,
    Color? color,
    Widget? indicator,
  })? loader;
  static Function({
    Widget? indicator,
    Color? progressColor,
    Color? backgroundColor,
    Color? indicatorColor,
    Color? textColor,
    Widget? success,
    Widget? error,
    Widget? info,
  })? config;
  @override
  Function? get loadingWidget => loader ?? super.loadingWidget;
  @override
  Function? get loadingconfig => config ?? super.loadingconfig;
  oneRequest({
    required super.url,
    required super.method,
    super.body,
    super.queryParameters,
    super.formData,
    super.header,
    super.maxRedirects,
    super.timeout,
    super.responsetype,
    super.contentType,
  });
}
