import 'dart:core';

import 'package:all_in_one_request/src/resourses/utils.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'model/error.dart';

// ignore: camel_case_types
class basehttpRequest {
  Map<String, dynamic>? body;
  Map<String, dynamic>? queryParameters;
  FormData? formData;
  String url;
  String method;
  Map<String, String>? header;
  int? maxRedirects = 1;
  int timeout = 60;
  Options? options;

  basehttpRequest({
    this.body,
    this.queryParameters,
    this.formData,
    required this.url,
    required this.method,
    this.header,
    this.maxRedirects,
    this.timeout = 60,
    this.options,
  }) {
    _httpequest(
      body: body,
      queryParameters: queryParameters,
      formData: formData,
      url: url,
      method: method,
      header: header,
      maxRedirects: maxRedirects,
      timeout: timeout,
      options: options,
    );
  }

  Future<Either<dynamic, CustomExceptionHandlers>> _httpequest({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    FormData? formData,
    required String url,
    required String method,
    Map<String, String>? header,
    int? maxRedirects = 1,
    int timeout = 60,
    Options? options,
  }) async {
    final dio = Dio();
    loading();
    var headers = header ??
        {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
    final response = await dio
        .request(
      url,
      data: body ?? formData,
      queryParameters: queryParameters,
      options: options ??
          Options(
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
