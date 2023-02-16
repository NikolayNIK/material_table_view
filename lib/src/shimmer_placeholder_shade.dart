import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/material_table_view.dart';

/// This widget creates [TablePlaceholderShade] that creates animated shimmer
/// effect for placeholders.
class ShimmerPlaceholderShadeProvider extends StatefulWidget {
  const ShimmerPlaceholderShadeProvider({
    super.key,
    required this.loopDuration,
    required this.colors,
    required this.stops,
    required this.builder,
    this.angle = pi / 4,
  }) : assert(
          colors.length == stops.length,
          'List of stops must have the same width as the list of colors',
        );

  /// The time it will take for the shimmer effect to repeat.
  final Duration loopDuration;

  /// List of colors used for the shimmer effect.
  final List<Color> colors;

  /// List of color stops in range of [0, 1].
  final List<double> stops;

  /// Shimmer direction in radians.
  final double angle;

  /// Builder function that should build the child utilizing the
  /// [TablePlaceholderShade] provided.
  final Widget Function(
    BuildContext context,
    TablePlaceholderShade placeholderShade,
  ) builder;

  @override
  State<ShimmerPlaceholderShadeProvider> createState() =>
      _ShimmerPlaceholderShadeProviderState();
}

class _ShimmerPlaceholderShadeProviderState
    extends State<ShimmerPlaceholderShadeProvider>
    with
        ChangeNotifier,
        SingleTickerProviderStateMixin<ShimmerPlaceholderShadeProvider>,
        TablePlaceholderShade {
  late Ticker _ticker;
  bool _ticking = false;
  double _position = .0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, this);

  @override
  set active(bool active) {
    if (_ticking != active) {
      if (_ticking = active) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  BlendMode get blendMode => BlendMode.srcIn;

  void _tick(Duration elapsed) {
    _position = elapsed.inMicroseconds / widget.loopDuration.inMicroseconds;
    _position = _position - _position.toInt();
    _position = 2 * _position - 1;

    notifyListeners();
  }

  @override
  Shader createShader(Rect bounds, double verticalOffsetPixels) {
    // Even though this radius can be shorter the more the angle aligns with
    // either axis, for now we just use the biggest.
    final radius =
        sqrt(bounds.width * bounds.width + bounds.height * bounds.height);
    final offset = Offset(
      radius * cos(widget.angle),
      radius * sin(widget.angle),
    );

    final center = bounds.center;

    return ui.Gradient.linear(
      center - offset,
      center + offset,
      widget.colors,
      widget.stops.map((e) => e + _position).toList(growable: false),
      TileMode.repeated,
    );
  }
}
