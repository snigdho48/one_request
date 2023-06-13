import 'dart:core';

import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:one_request/src/resourses/utils.dart';

import 'model/error.dart';

// ignore: camel_case_types
abstract class basehttpRequest {
  Map<String, dynamic>? body;
  Map<String, dynamic>? queryParameters;
  bool formData = false;
  String url;
  String method;
  Map<String, String>? header;
  int? maxRedirects = 1;
  int timeout = 60;
  Function? loadingWidget = loadingStuff.loading;
  Function? loadingconfig = loadingStuff.configLoading;
  Function? dismiss;
  String responsetype = 'json';
  String contentType = 'application/json';

  basehttpRequest({
    this.body,
    this.queryParameters,
    this.formData = false,
    required this.url,
    required this.method,
    this.header,
    this.maxRedirects,
    this.timeout = 60,
    this.responsetype = 'json',
    this.contentType = 'application/json',
  }) {
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
    );
  }

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
    loadingconfig;
    loadingWidget;
    var headers = header ??
        {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
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
      try {
        if (responseJson['status'] == false) {
          EasyLoading.showError(responseJson['message']);

          return Right(
            CustomExceptionHandlers(
              error: responseJson['message'],
            ),
          );
        } else {
          EasyLoading.showSuccess(responseJson['message']);
          return Left(responseJson);
        }
      } catch (e) {
        try {
          if (responseJson['success'] == false) {
            EasyLoading.showError(responseJson['message']);

            return Right(
              CustomExceptionHandlers(
                error: responseJson['message'],
              ),
            );
          } else {
            EasyLoading.showSuccess(responseJson['message']);
            return Left(responseJson);
          }
        } catch (e) {
          try {
            if (responseJson['data'] == null || responseJson['data'] == []) {
              EasyLoading.showError(responseJson['message']);

              return Right(
                CustomExceptionHandlers(
                  error: responseJson['message'],
                ),
              );
            } else {
              EasyLoading.showSuccess(responseJson['message']);
              return Left(responseJson);
            }
          } catch (e) {
            EasyLoading.showError(e.toString());
            return Right(CustomExceptionHandlers(error: e.toString()));
          }
        }
      }
    } else {
      EasyLoading.showError(response.statusMessage.toString());
      return Right(CustomExceptionHandlers(error: response.statusMessage));
    }
  }
}
