import 'dart:core';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:one_request/src/resourses/utils.dart';

import 'model/error.dart';

// ignore: camel_case_types
class oneRequest {
  // ignore: non_constant_identifier_names
  // initializer
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
  MultipartFile fileFromByte({required List<int> filebyte}) =>
      MultipartFile.fromBytes(
        filebyte,
      );
  // filefromString function
  MultipartFile fileFormString({required String filestring}) =>
      MultipartFile.fromString(
        filestring,
      );
// filefromFile function
  MultipartFile file({required File file, String? filename}) =>
      MultipartFile.fromFileSync(
        file.path,
        filename: filename ?? file.path.split('/').last,
      );

  // send request function constructor
  Future<Either<dynamic, CustomExceptionHandlers>> send({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    String? responsetype = 'json',
    required String url,
    required String method,
    Map<String, String>? header,
    int? maxRedirects = 1,
    String contentType = 'application/json',
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
    String? responsetype = 'json',
    required String url,
    required String method,
    Map<String, String>? header,
    int? maxRedirects = 1,
    String contentType = 'application/json',
    int timeout = 60,
    Options? options,
    bool innderData = false,
  }) async {
    ResponseType typeOfResponce = responsetype == 'json'
        ? ResponseType.json
        : responsetype == 'stream'
            ? ResponseType.stream
            : responsetype == 'plain'
                ? ResponseType.plain
                : responsetype == 'bytes'
                    ? ResponseType.bytes
                    : ResponseType.json;
    final dio = Dio();
    LoadingStuff.loading();
    var headers = header ??
        {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
    // main request
    final response = await dio
        .request(
          url,
          data: formData ? FormData.fromMap(body!) : body,
          queryParameters: queryParameters,
          options: options ??
              Options(
                contentType: contentType,
                responseType: typeOfResponce,
                followRedirects: maxRedirects != 1 ? true : false,
                method: method,
                headers: headers,
                maxRedirects: maxRedirects,
                validateStatus: (status) => true,
              ),
        )
        // error on request
        .onError((error, stackTrace) => Response(
            requestOptions: RequestOptions(path: url),
            statusCode: 00,
            statusMessage: error.toString()))
        // timeout on request
        .timeout(
      Duration(seconds: timeout),
      onTimeout: () {
        dio.close();
        return Response(
          data: {
            'success': false,
            'message': 'Request timeout',
          },
          statusCode: 408,
          requestOptions: RequestOptions(path: url),
        );
      },
    );

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseJson = await response.data;
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
