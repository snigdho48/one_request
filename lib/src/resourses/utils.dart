import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'circulerprogressindictor_customize.dart';

class loadingStuff {
  static loading({String? status, Color? color, Widget? indicator}) {
    EasyLoading.show(
      status: status ?? 'loading',
      indicator: indicator ??
          const SpinKitWave(
            color: Colors.blue,
            size: 50.0,
          ),
    );
  }

  static void configLoading(
      {Widget? indicator,
      Color? progressColor,
      Color? backgroundColor,
      Color? indicatorColor,
      Color? textColor}) {
    EasyLoading.instance
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..maskType = EasyLoadingMaskType.black
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = progressColor ?? Colors.pink
      ..backgroundColor = backgroundColor ?? Colors.white
      ..indicatorColor = indicatorColor ?? Colors.pink
      ..textColor = textColor ?? Colors.pink
      ..maskColor = Colors.blue.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false
      ..indicatorWidget = indicator ?? loading();
  }
}
