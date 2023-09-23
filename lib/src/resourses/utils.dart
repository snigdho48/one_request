/// This file contains the [LoadingStuff] class which provides methods for showing and dismissing loading indicators using the [EasyLoading] package.
/// It also provides a method for configuring the loading indicator with custom widgets and colors.
/// 
/// The [loading] method shows the loading indicator with an optional status message, color and custom indicator widget.
/// The [loadingDismiss] method dismisses the loading indicator.
/// The [configLoad] method configures the loading indicator with custom widgets and colors.
/// The [initLoading] getter initializes the [EasyLoading] package.
/// 
/// This file imports the following packages:
///   * flutter/material.dart
///   * flutter_easyloading/flutter_easyloading.dart
/// 
/// This file also imports the following files:
///   * circulerprogressindictor_customize.dart

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'circulerprogressindictor_customize.dart';

class LoadingStuff {
  static loading({String? status, Color? color, Widget? indicator}) {
    if (indicator != null) {
      return EasyLoading.show(
        status: status ?? 'loading',
        indicator: indicator,
      );
    } else {
      return EasyLoading.show(
        status: status ?? 'loading',
      );
    }
  }

  static loadingDismiss() {
    return EasyLoading.dismiss();
  }

  static void configLoad(
      {Widget? indicator,
      Widget? success,
      Widget? error,
      Widget? info,
      Color? progressColor,
      Color? backgroundColor,
      Color? indicatorColor,
      Color? textColor}) {
    WidgetsFlutterBinding.ensureInitialized();
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.black
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = progressColor ?? Colors.white
      ..backgroundColor = backgroundColor ?? Colors.black
      ..indicatorColor = indicatorColor ?? Colors.white
      ..textColor = textColor ?? Colors.white
      ..maskColor = Colors.blue.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false
      ..indicatorWidget = indicator ??
          const SizedBox(
            width: 150,
            child: SpinKitWave(
              color: Colors.white,
              size: 50.0,
            ),
          )
      ..successWidget = success ??
          const Icon(
            Icons.check,
            color: Colors.green,
          )
      ..errorWidget = error ??
          const Icon(
            Icons.error,
            color: Colors.red,
          )
      ..infoWidget = info ??
          const Icon(
            Icons.info,
            color: Colors.blue,
          );
  }

  static get initLoading => EasyLoading.init();
}
