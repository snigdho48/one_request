import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:one_request/src/resourses/types.dart';
import 'package:one_request/src/resourses/utils.dart';

import 'model/error.dart';

// ignore: camel_case_types
class oneRequest {
  // ignore: non_constant_identifier_names
  // initializer
  static get dismissLoading => LoadingStuff.loadingDismiss();
  static get initLoading => LoadingStuff.initLoading;
  static get loading => LoadingStuff.loading;
  // loading widget
  /// Displays a loading widget with an optional status message, color, and indicator widget.
  ///
  /// The [status] parameter is an optional message to display below the loading indicator.
  /// The [color] parameter is an optional color to use for the loading indicator.
  /// The [indicator] parameter is an optional widget to use as the loading indicator.
  static void loadingWidget({
    String? status,
    Color? color,
    Widget? indicator,
  }) =>
      LoadingStuff.loading(
        status: status,
        color: color,
        indicator: indicator,
      );
  // loading config
  /// Configures the loading widget for the DioRequest class.
  ///
  /// This method takes in several optional parameters that allow you to customize
  /// the appearance of the loading widget. You can specify the indicator widget,
  /// progress color, background color, indicator color, text color, success widget,
  /// error widget, and info widget.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// DioRequest.loadingconfig(
  ///   indicator: CircularProgressIndicator(),
  ///   progressColor: Colors.blue,
  ///   backgroundColor: Colors.white,
  ///   indicatorColor: Colors.red,
  ///   textColor: Colors.black,
  ///   success: Icon(Icons.check),
  ///   error: Icon(Icons.error),
  ///   info: Icon(Icons.info),
  /// );
  /// ```
  static void loadingconfig({
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

  // filefromByte function
  /// Returns a [dio.MultipartFile] object from a list of bytes.
  ///
  /// The [filebyte] parameter is a required list of bytes that represents the file.
  ///
  /// Example usage:
  /// ```dart
  /// final fileBytes = await File('path/to/file').readAsBytes();
  /// final multipartFile = dioRequest.fileFromByte(filebyte: fileBytes);
  /// ```
  dio.MultipartFile fileFromByte({required List<int> filebyte}) =>
      dio.MultipartFile.fromBytes(
        filebyte,
      );
  // filefromString function
  /// Returns a [dio.MultipartFile] object created from a string.
  ///
  /// The [filestring] parameter is a required string that represents the file content.
  ///
  /// Example usage:
  /// ```dart
  /// final file = dioRequest.fileFormString(filestring: 'file content');
  /// ```
  dio.MultipartFile fileFormString({required String filestring}) =>
      dio.MultipartFile.fromString(
        filestring,
      );
// filefromFile function
  /// Returns a [dio.MultipartFile] object from a [File] object.
  ///
  /// The [file] parameter is a required [File] object that represents the file to be uploaded.
  ///
  /// The [filename] parameter is an optional [String] that represents the name of the file to be uploaded. If not provided, the name of the file will be used.
  ///
  /// Example usage:
  /// ```
  /// final file = File('/path/to/file');
  /// final multipartFile = dioRequest.file(file: file, filename: 'my_file.txt');
  /// ```
  dio.MultipartFile file({required File file, String? filename}) =>
      dio.MultipartFile.fromFileSync(
        file.path,
        filename: filename ?? file.path.split('/').last,
      );

  // send request function constructor
  /// Sends an HTTP request with the given parameters and returns a [Future] that
  /// completes with an [Either] object containing either the response body or a
  /// [CustomExceptionHandlers] object if an error occurred.
  ///
  /// The [body] parameter is an optional map of key-value pairs to include in the
  /// request body. The [queryParameters] parameter is an optional map of key-value
  /// pairs to include in the request URL query string. The [formData] parameter
  /// specifies whether to send the request as form data. The [responsetype]
  /// parameter specifies the expected response type. The [url] parameter is the
  /// URL to send the request to. The [method] parameter is the HTTP method to use.
  /// The [header] parameter is an optional map of key-value pairs to include in
  /// the request headers. The [maxRedirects] parameter specifies the maximum
  /// number of redirects to follow. The [contentType] parameter specifies the
  /// content type of the request body. The [timeout] parameter specifies the
  /// number of seconds to wait for a response before timing out. The [innderData]
  /// parameter specifies whether to include the response data in the returned
  /// [Either] object.
  Future<Either<dynamic, CustomExceptionHandlers>> send({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    ResponseType responsetype = ResponseType.json,
    required String url,
    required RequestType method,
    Map<String, String>? header,
    int? maxRedirects = 1,
    ContentType contentType = ContentType.json,
    int timeout = 60,
    bool innderData = false,
    bool loader = true,
    bool resultOverlay = true,
  }) =>
      _httpequest(
        body: body,
        queryParameters: queryParameters,
        url: url,
        formData: formData,
        method: method,
        header: header,
        maxRedirects: maxRedirects,
        timeout: timeout,
        responsetype: responsetype,
        contentType: contentType,
        innderData: innderData,
        loader: loader,
        resultOverlay: resultOverlay,
      );
  // main request function
  /// Sends an HTTP request using Dio package.
  ///
  /// [body] is the request body.
  ///
  /// [queryParameters] is the query parameters of the request.
  ///
  /// [formData] is a boolean value indicating whether the request is a form data or not.
  ///
  /// [responsetype] is the response type of the request.
  ///
  /// [url] is the URL of the request.
  ///
  /// [method] is the HTTP method of the request.
  ///
  /// [header] is the header of the request.
  ///
  /// [maxRedirects] is the maximum number of redirects to follow.
  ///
  /// [contentType] is the content type of the request.
  ///
  /// [timeout] is the timeout duration of the request.
  ///
  /// [options] is the options of the request.
  ///
  /// [innderData] is a boolean value indicating whether to return the inner data of the response or not.
  ///
  /// Returns a [Future] of [Either] of dynamic and [CustomExceptionHandlers].
  Future<Either<dynamic, CustomExceptionHandlers>> _httpequest({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    ResponseType responsetype = ResponseType.json,
    required String url,
    required RequestType method,
    Map<String, String>? header,
    int? maxRedirects = 1,
    ContentType contentType = ContentType.json,
    int timeout = 60,
    dio.Options? options,
    bool innderData = false,
    bool loader = true,
    bool resultOverlay = true,
  }) async {
    final r = dio.Dio();
    if (loader) {
      LoadingStuff.loading();
    }
    var headers = header ??
        {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
    // main request
    final response = await r
        .request(
          url,
          data: formData ? dio.FormData.fromMap(body!) : body,
          queryParameters: queryParameters,
          options: options ??
              dio.Options(
                contentType: contentType.value,
                responseType: responsetype.value,
                followRedirects: maxRedirects != 1 ? true : false,
                method: method.value,
                headers: headers,
                maxRedirects: maxRedirects,
                validateStatus: (status) => true,
              ),
        )
        // error on request
        .onError((error, stackTrace) => dio.Response(
            requestOptions: dio.RequestOptions(path: url),
            statusCode: 00,
            statusMessage: error.toString()))
        // timeout on request
        .timeout(
      Duration(seconds: timeout),
      onTimeout: () {
        r.close();
        return dio.Response(
          data: {
            'success': false,
            'message': 'Request timeout',
          },
          statusCode: 408,
          requestOptions: dio.RequestOptions(path: url),
        );
      },
    );

    if (loader) {
      EasyLoading.dismiss();
    }

    if (response.statusCode == 200) {
      final responseJson = await response.data;
      if (innderData) {
        try {
          if (responseJson['data'] != null && responseJson['data'] != '') {
            return Left(responseJson['data']);
          } else {
            if (resultOverlay) {
              EasyLoading.showSuccess(responseJson['message'].toString());
            }
            return Right(responseJson['message']);
          }
        } catch (e) {
          if (resultOverlay) {
            EasyLoading.showError(
                CustomExceptionHandlers(error: e).getExceptionString());
          }
          return Right(CustomExceptionHandlers(error: e).getExceptionString());
        }
      }
      if (resultOverlay) {
        EasyLoading.showSuccess(response.statusMessage.toString());
      }
      return Left(responseJson);
    } else {
      if (resultOverlay) {
        EasyLoading.showError(response.statusMessage.toString());
      }
      return Right(
          CustomExceptionHandlers(error: response).getExceptionString());
    }
  }
}
