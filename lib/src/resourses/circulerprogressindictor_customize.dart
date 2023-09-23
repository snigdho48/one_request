import 'package:flutter/material.dart';

import 'dart:math' as math show sin, pi;

/// An enumeration of the different types of wave animations for a circular progress indicator.
enum SpinKitWaveType {
  /// The wave animation starts from the beginning.
  start,

  /// The wave animation ends at the end.
  end,

  /// The wave animation starts from the center.
  center,
}
// ignore: camel_case_types

/// A custom [Tween] that adds a delay to the animation.
class DelayTween extends Tween<double> {
  /// Creates a [DelayTween] with the given [begin], [end], and [delay] values.
  DelayTween({double? begin, double? end, required this.delay})
      : super(begin: begin, end: end);

  /// The delay to be added to the animation.
  final double delay;

  @override
  double lerp(double t) =>
      super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}

/// A customizable wave-shaped progress indicator.
/// A customizable circular progress indicator with wave animation.
///
/// This widget is a stateful widget that creates a circular progress indicator with wave animation.
/// It can be customized with various properties such as color, size, number of wave bars, duration of animation, etc.
/// The wave animation can also be customized with different types of wave animations.
///
/// Example usage:
/// ```dart
/// SpinKitWave(
///   color: Colors.blue,
///   size: 50.0,
///   itemCount: 5,
///   duration: Duration(milliseconds: 2500),
/// )
/// ```
class SpinKitWave extends StatefulWidget {
  const SpinKitWave({
    Key? key,
    this.color,
    this.type = SpinKitWaveType.start,
    this.size = 50.0,
    this.itemBuilder,
    this.itemCount = 5,
    this.duration = const Duration(milliseconds: 2500),
    this.controller,
  })  : assert(
            !(itemBuilder is IndexedWidgetBuilder && color is Color) &&
                !(itemBuilder == null && color == null),
            'You should specify either a itemBuilder or a color'),
        assert(itemCount >= 2, 'itemCount Cant be less then 2 '),
        super(key: key);

  /// The color of the progress indicator.
  final Color? color;

  /// The number of wave bars in the progress indicator.
  final int itemCount;

  /// The size of the progress indicator.
  final double size;

  /// The type of wave animation to use.
  final SpinKitWaveType type;

  /// A builder for the wave bars in the progress indicator.
  final IndexedWidgetBuilder? itemBuilder;

  /// The duration of the animation.
  final Duration duration;

  /// An optional [AnimationController] to use for the animation.
  final AnimationController? controller;

  @override
  // ignore: library_private_types_in_public_api
  _SpinKitWaveState createState() => _SpinKitWaveState();
}

class _SpinKitWaveState extends State<SpinKitWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// Initializes the state of the widget.
  ///
  /// This method is called when this widget is inserted into the tree.
  /// It sets the [_controller] to an [AnimationController] instance with the given [widget.duration] and [this] as the [vsync].
  /// If [widget.controller] is not null, then it uses that instead of creating a new instance.
  /// Finally, it calls the [repeat] method on the [_controller] to repeat the animation.
  @override
  void initState() {
    super.initState();

    _controller = (widget.controller ??
        AnimationController(vsync: this, duration: widget.duration))
      ..repeat();
  }

  /// Overrides the [State.dispose] method to dispose the [_controller] object if [widget.controller] is null.
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Builds a customized circular progress indicator widget with a given size and item count.
  ///
  /// The widget is centered and consists of a row of [widget.itemCount] items, each of which is built using the [_itemBuilder] function.
  /// The items are spaced evenly and scaled vertically using the [ScaleYWidget] widget.
  /// The animation delay for each item is determined by the [getAnimationDelay] function.
  ///
  /// The widget is built using a [SizedBox] with a size of [widget.size * 1.5, widget.size] to ensure that it is large enough to accommodate the items.
  ///
  /// Returns a [Center] widget containing the customized circular progress indicator.
  @override
  Widget build(BuildContext context) {
    final List<double> bars = getAnimationDelay(widget.itemCount);
    return Center(
      child: SizedBox.fromSize(
        size: Size(widget.size * 1.5, widget.size),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(bars.length, (i) {
            return ScaleYWidget(
              scaleY: DelayTween(begin: .3, end: 1.0, delay: bars[i])
                  .animate(_controller),
              child: SizedBox.fromSize(
                  size: Size(widget.size / widget.itemCount, widget.size),
                  child: _itemBuilder(i)),
            );
          }),
        ),
      ),
    );
  }

  /// Returns a list of delays for the wave animation based on the [itemCount] and [type].
  /// Returns a list of double values representing the animation delay for each item in the circular progress indicator based on the selected [SpinKitWaveType].
  ///
  /// The [itemCount] parameter specifies the number of items in the circular progress indicator.
  ///
  /// The [SpinKitWaveType] enum specifies the type of wave animation to be used for the circular progress indicator. The available options are:
  ///
  /// * `SpinKitWaveType.start`: The wave animation starts from the beginning of the circular progress indicator.
  /// * `SpinKitWaveType.end`: The wave animation starts from the end of the circular progress indicator.
  /// * `SpinKitWaveType.center`: The wave animation starts from the center of the circular progress indicator.
  ///
  /// Returns a list of double values representing the animation delay for each item in the circular progress indicator.
  List<double> getAnimationDelay(int itemCount) {
    switch (widget.type) {
      case SpinKitWaveType.start:
        return _startAnimationDelay(itemCount);
      case SpinKitWaveType.end:
        return _endAnimationDelay(itemCount);
      case SpinKitWaveType.center:
      default:
        return _centerAnimationDelay(itemCount);
    }
  }

  /// Returns a list of delays for the wave animation starting from the left.
  /// Returns a list of delays for animating a circular progress indicator.
  ///
  /// The [count] parameter specifies the number of delays to generate. The delays
  /// are returned as a list of doubles, where each delay is a negative value.
  /// The delays are generated in a way that creates a wave-like animation effect.
  List<double> _startAnimationDelay(int count) {
    return <double>[
      ...List<double>.generate(
          count ~/ 2, (index) => -1.0 - (index * 0.1) - 0.1).reversed,
      if (count.isOdd) -1.0,
      ...List<double>.generate(
        count ~/ 2,
        (index) => -1.0 + (index * 0.1) + (count.isOdd ? 0.1 : 0.0),
      ),
    ];
  }

  /// Returns a list of delays for the wave animation starting from the right.
  /// Returns a list of delays for animating the end of a circular progress indicator.
  ///
  /// The [count] parameter specifies the number of delays to generate.
  /// The delays are calculated based on the count and returned as a list of doubles.
  /// The first half of the delays are generated in reverse order, starting from -1.0 and incrementing by 0.1.
  /// If the count is odd, a delay of -1.0 is added to the middle of the list.
  /// The second half of the delays are generated in ascending order, starting from -1.0 and decrementing by 0.1.
  /// If the count is odd, an additional decrement of 0.1 is added to the last delay.
  List<double> _endAnimationDelay(int count) {
    return <double>[
      ...List<double>.generate(
          count ~/ 2, (index) => -1.0 + (index * 0.1) + 0.1).reversed,
      if (count.isOdd) -1.0,
      ...List<double>.generate(
        count ~/ 2,
        (index) => -1.0 - (index * 0.1) - (count.isOdd ? 0.1 : 0.0),
      ),
    ];
  }

  /// Returns a list of delays for animating the center of a circular progress indicator.
  ///
  /// The [count] parameter specifies the number of circles in the progress indicator.
  /// The returned list contains delays for each circle, with the center circle having a delay of 0.
  /// The delays are calculated such that the circles closer to the center have a longer delay,
  /// resulting in a staggered animation effect.
  List<double> _centerAnimationDelay(int count) {
    return <double>[
      ...List<double>.generate(
          count ~/ 2, (index) => -1.0 + (index * 0.2) + 0.2).reversed,
      if (count.isOdd) -1.0,
      ...List<double>.generate(
          count ~/ 2, (index) => -1.0 + (index * 0.2) + 0.2),
    ];
  }

  /// Builds a widget for each item in the list using the [itemBuilder] callback.
  /// If [itemBuilder] is null, it returns a [DecoratedBox] with the [color] specified in the [CircularProgressIndicatorCustomize] widget.
  ///
  /// The [index] parameter is the index of the current item being built.
  /// The [context] parameter is the build context.
  Widget _itemBuilder(int index) => widget.itemBuilder != null
      ? widget.itemBuilder!(context, index)
      : DecoratedBox(
          decoration: BoxDecoration(
          color: widget.color,
        ));
}

/// An animated widget that scales its child along the Y-axis.
class ScaleYWidget extends AnimatedWidget {
  /// A widget that scales its child vertically based on an animation.
  ///
  /// The [child] parameter is required and specifies the widget to be scaled.
  ///
  /// The [scaleY] parameter is required and specifies the animation to be used for scaling.
  ///
  /// The [alignment] parameter is optional and specifies the alignment of the child widget within the parent widget.
  final Widget child;
  final Alignment alignment;
  const ScaleYWidget({
    Key? key,
    required Animation<double> scaleY,
    required this.child,
    this.alignment = Alignment.center,
  }) : super(key: key, listenable: scaleY);

  /// Returns the animation scale as an [Animation<double>].
  Animation<double> get scale => listenable as Animation<double>;

  /// Builds a widget that applies a vertical scale transformation to its child.
  ///
  /// The [Transform] widget applies a [Matrix4] transformation to its child. In this case, the transformation is a vertical scaling effect, which is controlled by the [scale] value. The [alignment] parameter specifies the point around which the scaling is performed. The [child] parameter is the widget that is transformed.
  ///
  /// The method returns a [Widget] object that applies the transformation to the child widget.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return Transform(
  ///       transform: Matrix4.identity()..scale(1.0, scale.value, 1.0),
  ///       alignment: alignment,
  ///       child: child);
  /// }
  /// ```
  @override
  Widget build(BuildContext context) {
    return Transform(
        transform: Matrix4.identity()..scale(1.0, scale.value, 1.0),
        alignment: alignment,
        child: child);
  }
}
