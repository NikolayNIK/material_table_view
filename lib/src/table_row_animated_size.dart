// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'transitions.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/src/table_painting_context.dart';

/// [AnimatedSize] alternative that works in the [TableView.rowBuilder].
///
/// As oppose to the [AnimatedSize], this widget does not create its own
/// [TickerProvider] for performance reasons. That way a single provider
/// can be used to animate all rows of a table.
class TableRowAnimatedSize extends SingleChildRenderObjectWidget {
  const TableRowAnimatedSize({
    super.key,
    required super.child,
    this.alignment = Alignment.center,
    this.curve = Curves.linear,
    required this.duration,
    this.reverseDuration,
    required this.vsync,
    this.clipBehavior = Clip.hardEdge,
    this.onEnd,
  });

  /// See [AnimatedSize.alignment].
  final AlignmentGeometry alignment;

  /// See [AnimatedSize.curve].
  final Curve curve;

  /// See [AnimatedSize.duration].
  final Duration duration;

  /// See [AnimatedSize.reverseDuration].
  final Duration? reverseDuration;

  /// A ticker provider for the animation.
  /// Typically, [TickerProviderStateMixin].
  final TickerProvider vsync;

  /// See [AnimatedSize.clipBehavior].
  final Clip clipBehavior;

  /// See [AnimatedSize.onEnd].
  final VoidCallback? onEnd;

  @override
  RenderAnimatedSize createRenderObject(BuildContext context) =>
      _RenderTableRowAnimatedSize(
        alignment: alignment,
        duration: duration,
        reverseDuration: reverseDuration,
        curve: curve,
        vsync: vsync,
        textDirection: Directionality.maybeOf(context),
        clipBehavior: clipBehavior,
        onEnd: onEnd,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAnimatedSize renderObject,
  ) =>
      renderObject
        ..alignment = alignment
        ..duration = duration
        ..reverseDuration = reverseDuration
        ..curve = curve
        ..vsync = vsync
        ..textDirection = Directionality.maybeOf(context)
        ..clipBehavior = clipBehavior
        ..onEnd = onEnd;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<AlignmentGeometry>(
        'alignment',
        alignment,
        defaultValue: Alignment.topCenter,
      ),
    );
    properties
        .add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
    properties.add(
      IntProperty(
        'reverseDuration',
        reverseDuration?.inMilliseconds,
        unit: 'ms',
        defaultValue: null,
      ),
    );
  }
}

class _RenderTableRowAnimatedSize extends RenderAnimatedSize {
  _RenderTableRowAnimatedSize({
    required super.vsync,
    required super.duration,
    super.reverseDuration,
    super.curve,
    super.alignment,
    super.textDirection,
    super.clipBehavior,
    super.onEnd,
  });

  bool get _hasVisualOverflow => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _hasVisualOverflow && clipBehavior != Clip.none) {
      final Rect rect = offset & size;

      if (context is TablePaintingContext) {
        context.pushLayers(
          () => ClipRectLayer(
            clipRect: rect,
            clipBehavior: clipBehavior,
          ),
          _paint,
          offset,
        );
      } else {
        context.pushClipRect(
          needsCompositing,
          offset,
          rect,
          _paint,
          clipBehavior: clipBehavior,
        );
      }
    } else {
      _paint(context, offset);
    }
  }

  void _paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child != null) {
      final BoxParentData childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }
}
