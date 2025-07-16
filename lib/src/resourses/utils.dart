import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'circulerprogressindictor_customize.dart';

typedef LoadingWidgetBuilder = Widget Function(
    BuildContext context, String? status);
typedef ErrorWidgetBuilder = Widget Function(
    BuildContext context, String message);
typedef ErrorLocalization = String Function(String message);

/// A utility class for displaying loading indicators using EasyLoading.
class LoadingStuff {
  static LoadingWidgetBuilder? customLoadingBuilder;
  static ErrorWidgetBuilder? customErrorBuilder;
  static ErrorLocalization? errorLocalization;

  /// Set custom widget builders and error localization.
  static void setCustomBuilders({
    LoadingWidgetBuilder? loadingBuilder,
    ErrorWidgetBuilder? errorBuilder,
    ErrorLocalization? localization,
  }) {
    customLoadingBuilder = loadingBuilder;
    customErrorBuilder = errorBuilder;
    errorLocalization = localization;
  }

  static void resetCustomBuilders() {
    customLoadingBuilder = null;
    customErrorBuilder = null;
    errorLocalization = null;
  }

  /// Displays a loading indicator with an optional status message, color, and custom widget.
  ///
  /// If [indicator] is provided, it will be used as the loading indicator. Otherwise, the default
  /// loading indicator will be used.
  ///
  /// If [status] is provided, it will be displayed as the status message for the loading indicator.
  /// Otherwise, the default status message "loading" will be used.
  static loading(
      {String? status,
      Color? color,
      Widget? indicator,
      BuildContext? context}) {
    if (customLoadingBuilder != null && context != null) {
      return EasyLoading.show(
        status: status ?? 'loading',
        indicator: customLoadingBuilder!(context, status),
      );
    } else if (indicator != null) {
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

  /// Dismisses the loading indicator.
  static loadingDismiss() {
    return EasyLoading.dismiss();
  }

  /// Show a custom error widget if provided, otherwise use EasyLoading default.
  static void showError(String message, {BuildContext? context}) {
    final localizedMsg =
        errorLocalization != null ? errorLocalization!(message) : message;
    if (customErrorBuilder != null && context != null) {
      final prevErrorWidget = EasyLoading.instance.errorWidget;
      EasyLoading.instance.errorWidget =
          customErrorBuilder!(context, localizedMsg);
      EasyLoading.showError(localizedMsg);
      // Optionally reset after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        EasyLoading.instance.errorWidget = prevErrorWidget;
      });
    } else {
      EasyLoading.showError(localizedMsg);
    }
  }

  /// A utility class that provides a method to configure the EasyLoading plugin.
  /// Configures the EasyLoading plugin with the given parameters.
  ///
  /// [indicator] is the widget to be displayed as the loading indicator.
  ///
  /// [success] is the widget to be displayed when the loading is successful.
  ///
  /// [error] is the widget to be displayed when the loading fails.
  ///
  /// [info] is the widget to be displayed when the loading is in progress.
  ///
  /// [progressColor] is the color of the progress indicator.
  ///
  /// [backgroundColor] is the background color of the loading widget.
  ///
  /// [indicatorColor] is the color of the loading indicator.
  ///
  /// [textColor] is the color of the text displayed with the loading widget.
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
      ..maskColor = Colors.blue.shade500
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

  /// Initializes the EasyLoading plugin.
  static get initLoading => EasyLoading.init();
}
