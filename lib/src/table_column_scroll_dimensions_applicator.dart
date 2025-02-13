import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_column.dart';

/// This widget provides a strait forward (dumb) way to set
/// known in advance dimensions of a [ScrollPosition].
class TableColumnScrollDimensionsApplicator
    extends SingleChildRenderObjectWidget {
  final ScrollPosition position;
  final List<TableColumn> columns;
  final EdgeInsets scrollPadding;
  final bool _box;

  const TableColumnScrollDimensionsApplicator.box({
    super.key,
    required this.position,
    required this.columns,
    required this.scrollPadding,
    required super.child,
  }) : _box = true;

  const TableColumnScrollDimensionsApplicator.sliver({
    super.key,
    required this.position,
    required this.columns,
    required this.scrollPadding,
    required super.child,
  }) : _box = false;

  @override
  RenderObject createRenderObject(BuildContext context) => _box
      ? _RenderBoxScrollDimensionsApplicator(
          position,
          _scrollExtent,
        )
      : _RenderSliverScrollDimensionsApplicator(
          position,
          _scrollExtent,
        );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderScrollDimensionsApplicator renderObject,
  ) {
    assert(
      _box
          ? renderObject is _RenderBoxScrollDimensionsApplicator
          : renderObject is _RenderSliverScrollDimensionsApplicator,
    );

    super.updateRenderObject(context, renderObject);

    renderObject
      ..scrollPosition = position
      ..scrollExtent = _scrollExtent;
  }

  double get _scrollExtent =>
      columns.fold<double>(
          .0, (previousValue, element) => previousValue + element.width) +
      scrollPadding.horizontal;
}

mixin RenderScrollDimensionsApplicator on RenderObject {
  set scrollPosition(ScrollPosition position);

  set scrollExtent(double scrollExtent);
}

class _RenderBoxScrollDimensionsApplicator extends RenderProxyBox
    with RenderScrollDimensionsApplicator {
  ScrollPosition scrollPosition;
  double _scrollExtent;

  _RenderBoxScrollDimensionsApplicator(
    this.scrollPosition,
    this._scrollExtent,
  );

  @override
  set scrollExtent(double scrollExtent) {
    if (scrollExtent != _scrollExtent) {
      _scrollExtent = scrollExtent;
      markNeedsLayout();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    super.performLayout();

    final viewportDimension = size.width;
    scrollPosition.applyViewportDimension(viewportDimension);
    scrollPosition.applyContentDimensions(
      0,
      max(.0, _scrollExtent - viewportDimension),
    );
  }
}

class _RenderSliverScrollDimensionsApplicator extends RenderProxySliver
    with RenderScrollDimensionsApplicator {
  ScrollPosition scrollPosition;
  double _scrollExtent;

  _RenderSliverScrollDimensionsApplicator(
    this.scrollPosition,
    this._scrollExtent,
  );

  @override
  set scrollExtent(double scrollExtent) {
    if (scrollExtent != _scrollExtent) {
      _scrollExtent = scrollExtent;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();

    final viewportDimension = geometry!.crossAxisExtent!;
    scrollPosition.applyViewportDimension(viewportDimension);
    scrollPosition.applyContentDimensions(
      0,
      max(.0, _scrollExtent - viewportDimension),
    );
  }
}
