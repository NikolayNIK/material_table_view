import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_typedefs.dart';

/// The function that builds a row using a cell builder passed to it.
/// This both for API compatibility reasons and to not expose [TableViewRow]
/// widget itself to the user (although I'm not sure about the last point).
Widget contentBuilder(BuildContext context, TableCellBuilder cellBuilder) =>
    TableViewRow(cellBuilder: cellBuilder);

/// The function that builds a row drawn on a placeholder layers
/// using a cell builder passed to it.
/// This both for API compatibility reasons and to not expose [TableViewRow]
/// widget itself to the user (although I'm not sure about the last point).
Widget placeholderContentBuilder(
        BuildContext context, TableCellBuilder cellBuilder) =>
    TableViewRow(cellBuilder: cellBuilder, usePlaceholderLayers: true);

/// This is the row widget used to build a single row of a table using layout
/// data provided by the [TableContentLayout] widget.
///
/// It ends the custom compositing process by painting each cell on a single
/// designated layer.
class TableViewRow extends StatelessWidget {
  final TableCellBuilder cellBuilder;
  final bool usePlaceholderLayers;

  const TableViewRow({
    super.key,
    required this.cellBuilder,
    this.usePlaceholderLayers = false,
  });

  @override
  Widget build(BuildContext context) {
    // TODO implement caching in the element tree instead
    Map<Key, Widget> previousCells = {};

    return Builder(
      builder: (context) {
        final data = TableContentLayout.of(context);

        final newCells = <Key, Widget>{};

        Iterable<Widget> columnMapper(
          TableContentColumnData columnData,
          bool scrolled,
        ) =>
            Iterable.generate(columnData.indices.length).map((i) {
              final columnIndex = columnData.indices[i];
              final columnKey = columnData.keys[i];
              return _TableViewCell(
                key: columnKey,
                width: columnData.widths[i],
                // height: data.rowHeight,
                position: columnData.positions[i],
                scrolled: scrolled,
                child: newCells[columnKey] = previousCells[columnKey] ??
                    Builder(
                        builder: (context) =>
                            cellBuilder(context, columnIndex)),
              );
            });

        final children = [
          ...columnMapper(data.fixedColumns, false),
          ...columnMapper(data.scrollableColumns, true),
        ];

        previousCells = newCells;

        return _TableViewRow(
          usePlaceholderLayers: usePlaceholderLayers,
          children: children,
        );
      },
    );
  }
}

class _TableViewRow extends MultiChildRenderObjectWidget {
  final bool usePlaceholderLayers;

  const _TableViewRow({
    required this.usePlaceholderLayers,
    required super.children,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableViewRow(usePlaceholderLayers: usePlaceholderLayers);
}

class _RenderTableViewRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _TableViewCellParentData> {
  _RenderTableViewRow({required bool usePlaceholderLayers})
      : _usePlaceholderLayers = usePlaceholderLayers;

  bool _usePlaceholderLayers;

  /// Cut off compositing requirement here to let the children use compositing.
  ///
  /// Operations which may need to know the actual need for compositing
  /// are strictly forbidden in parent render objects by the
  /// [TablePaintingContext], usage of which ends here.
  @override
  bool get needsCompositing => false;

  set usePlaceholderLayers(bool usePlaceholderLayers) {
    if (_usePlaceholderLayers != usePlaceholderLayers) {
      _usePlaceholderLayers = usePlaceholderLayers;
      markNeedsPaint();
    }
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! _TableViewCellParentData) {
      child.parentData = _TableViewCellParentData();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData as _TableViewCellParentData;
      child.layout(BoxConstraints(
        minWidth: parentData.width,
        maxWidth: parentData.width,
        minHeight: constraints.maxHeight,
        maxHeight: constraints.maxHeight,
      ));

      parentData.offset = Offset(parentData.position, 0);

      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context = context as TablePaintingContext;
    final pair = _usePlaceholderLayers ? context.placeholder : context.regular;

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData as _TableViewCellParentData;
      (parentData.scrollable ? pair.scrolled : pair.fixed).paintChild(
          child, Offset(offset.dx + parentData.position, offset.dy));

      child = parentData.nextSibling;
    }
  }

  RenderTableSection? get _nearestTableSectionAncestor {
    var node = parent;
    while (node != null) {
      if (node is RenderTableSection) {
        return node;
      }

      node = node.parent;
    }

    assert(false, 'No RenderTableSection ancestor found');
    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final scrolledClipPath =
        _nearestTableSectionAncestor!.scrolledSectionClipPath;

    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as _TableViewCellParentData;
      if ((!childParentData.scrollable ||
              scrolledClipPath.contains(position)) &&
          result.addWithPaintOffset(
            offset: childParentData.offset,
            position: position,
            hitTest: (BoxHitTestResult result, Offset transformed) {
              assert(transformed == position - childParentData.offset);
              return child!.hitTest(result, position: transformed);
            },
          )) {
        return true;
      }

      child = childParentData.previousSibling;
    }

    return false;
  }
}

class _TableViewCellParentData extends ContainerBoxParentData<RenderBox> {
  late double width;
  late double position;
  late bool scrollable;

  _TableViewCellParentData();
}

class _TableViewCell extends ParentDataWidget<_TableViewCellParentData> {
  final double width;
  final double position;
  final bool scrolled;

  const _TableViewCell({
    super.key,
    required this.width,
    required this.position,
    required this.scrolled,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData as _TableViewCellParentData;
    data.width = width;
    data.position = position;
    data.scrollable = scrolled;

    final parent = renderObject.parent;
    if (parent is RenderObject) {
      parent.markNeedsLayout();
      parent.markNeedsPaint();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => TableViewRow;
}
