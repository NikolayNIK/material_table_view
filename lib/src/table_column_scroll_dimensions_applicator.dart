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

  const TableColumnScrollDimensionsApplicator({
    super.key,
    required this.position,
    required this.columns,
    required this.scrollPadding,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderScrollDimensionsApplicator(
        position,
        _scrollExtent,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderScrollDimensionsApplicator renderObject,
  ) {
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

class RenderScrollDimensionsApplicator extends RenderProxyBox {
  RenderScrollDimensionsApplicator(
    this._scrollPosition,
    this._scrollExtent,
  );

  ScrollPosition _scrollPosition;
  double _scrollExtent;

  set scrollPosition(ScrollPosition scrollPosition) {
    if (!identical(_scrollPosition, scrollPosition)) {
      _scrollPosition = scrollPosition;
      markNeedsLayout();
    }
  }

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
    _scrollPosition.applyViewportDimension(viewportDimension);
    _scrollPosition.applyContentDimensions(
      0,
      max(.0, _scrollExtent - viewportDimension),
    );
  }
}
