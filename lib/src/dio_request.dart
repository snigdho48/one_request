/// This file contains the implementation of the `oneRequest` class, which provides a simple interface for making HTTP requests using the `dio` package.
///
/// The `oneRequest` class provides methods for sending HTTP requests with various options such as request body, query parameters, headers, and more. It also provides methods for configuring and displaying loading indicators using the `flutter_easyloading` package.
///
/// The class also includes helper methods for creating `dio.MultipartFile` objects from bytes, strings, and files.
///
/// The `send` method is the main method for sending HTTP requests, and it returns an `Either` object that contains either the response data or a `CustomExceptionHandlers` object in case of an error.
///
/// The `_httpequest` method is the private method that actually sends the HTTP request using the `dio` package. It handles errors and timeouts and returns a `dio.Response` object.
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
  dio.MultipartFile fileFromByte({required List<int> filebyte}) =>
      dio.MultipartFile.fromBytes(
        filebyte,
      );
  // filefromString function
  dio.MultipartFile fileFormString({required String filestring}) =>
      dio.MultipartFile.fromString(
        filestring,
      );
// filefromFile function
  dio.MultipartFile file({required File file, String? filename}) =>
      dio.MultipartFile.fromFileSync(
        file.path,
        filename: filename ?? file.path.split('/').last,
      );

  // send request function constructor
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
      );
  // main request function
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
  }) async {
    final r = dio.Dio();
    LoadingStuff.loading();
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

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      final responseJson = await response.data;
      if (innderData) {
        try {
          if (responseJson['data'] != null && responseJson['data'] != '') {
            return Left(responseJson['data']);
          } else {
            EasyLoading.showError(responseJson['message'].toString());
            return Right(responseJson['message']);
          }
        } catch (e) {
          EasyLoading.showError(e.toString());
          return Right(CustomExceptionHandlers(error: e.toString()));
        }
      }
      EasyLoading.showSuccess(response.statusMessage.toString());
      return Left(responseJson);
    } else {
      EasyLoading.showError(response.statusMessage.toString());
      return Right(CustomExceptionHandlers(error: response.statusMessage));
    }
  }
}
