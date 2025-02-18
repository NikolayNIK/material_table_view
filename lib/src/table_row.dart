import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/render_table_section.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_typedefs.dart';

/// The function that builds a row using a cell builder passed to it.
/// This both for API compatibility reasons and to not expose [TableViewRow]
/// widget itself to the user (although I'm not sure about the last point).
Widget contentBuilder(BuildContext context, TableCellBuilder cellBuilder) =>
    TableViewRow(cellBuilder: cellBuilder);

/// The function that builds a row using a cell builder passed to it.
/// This both for API compatibility reasons and to not expose [TableViewRow]
/// widget itself to the user (although I'm not sure about the last point).
Widget headerFooterContentBuilder(
        BuildContext context, TableCellBuilder cellBuilder) =>
    TableViewRow(
      cellBuilder: cellBuilder,
      fixedRowHeightOverride: true,
    );

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
class TableViewRow extends RenderObjectWidget {
  final TableCellBuilder cellBuilder;
  final bool usePlaceholderLayers;
  final bool? fixedRowHeightOverride;

  const TableViewRow({
    super.key,
    required this.cellBuilder,
    this.usePlaceholderLayers = false,
    this.fixedRowHeightOverride,
  });

  @override
  RenderObjectElement createElement() => _TableViewRowElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableViewRow();
}

class _TableCellSlot {
  final Key key;

  final double width;
  final bool scrolled;
  final double position;

  const _TableCellSlot({
    required this.key,
    required this.width,
    required this.scrolled,
    required this.position,
  });
}

class _TableViewRowElement extends RenderObjectElement {
  _TableViewRowElement(TableViewRow super.widget);

  final children = <Key, _TableViewCellElement>{};

  bool _debugDoingBuild = false;

  @override
  bool get debugDoingBuild => _debugDoingBuild || super.debugDoingBuild;

  @override
  TableViewRow get widget => super.widget as TableViewRow;

  @override
  _RenderTableViewRow get renderObject =>
      super.renderObject as _RenderTableViewRow;

  @override
  void visitChildren(ElementVisitor visitor) {
    children.values.forEach(visitor);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    rebuild(force: true);
  }

  @override
  void update(covariant RenderObjectWidget newWidget) {
    super.update(newWidget);

    rebuild(force: true);
  }

  @override
  // ignore: must_call_super
  void didChangeDependencies() {
    final data = TableContentLayout.of(this);

    _updateRenderObject(data);

    _updateChildren(data);
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);

    children.removeWhere((key, value) => identical(value, child));
  }

  @override
  void insertRenderObjectChild(RenderBox child, _TableCellSlot slot) {
    renderObject.insert(child, slot);
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    _TableCellSlot oldSlot,
    _TableCellSlot newSlot,
  ) {
    renderObject.move(child, oldSlot, newSlot);
  }

  @override
  void removeRenderObjectChild(
    RenderBox child,
    _TableCellSlot slot,
  ) {
    renderObject.remove(child, slot);
  }

  @override
  void performRebuild() {
    assert(() {
      _debugDoingBuild = true;
      return true;
    }());

    final data = TableContentLayout.of(this);

    _updateRenderObject(data);

    _updateChildren(data);

    super.performRebuild();

    assert(() {
      _debugDoingBuild = false;
      return true;
    }());
  }

  void _updateRenderObject(TableContentLayoutData data) {
    renderObject.usePlaceholderLayers = widget.usePlaceholderLayers;
    renderObject.fixedRowHeight =
        widget.fixedRowHeightOverride ?? data.fixedRowHeight;
    renderObject.foregroundColumnKey = data.foregroundColumnKey;
  }

  void _updateChildren(TableContentLayoutData data) {
    final leftoverChildren = Map.of(children);

    _updateCells(data.fixedColumns, leftoverChildren, false);
    _updateCells(data.scrollableColumns, leftoverChildren, true);

    leftoverChildren.values.forEach(deactivateChild);
    leftoverChildren.keys.forEach(children.remove);
  }

  void _updateCells(
    TableContentColumnData data,
    Map<Key, Element> leftoverChildren,
    bool scrolled,
  ) {
    final length = data.indices.length;
    for (var index = 0; index < length; index++) {
      final columnKey = data.keys[index];

      final newSlot = _TableCellSlot(
        key: columnKey,
        width: data.widths[index],
        scrolled: scrolled,
        position: data.positions[index],
      );

      final child = children[columnKey];

      final newWidget = _TableViewCell(
        key: columnKey,
        cellBuilder: widget.cellBuilder,
        index: data.indices[index],
      );

      if (child == null) {
        children[columnKey] =
            inflateWidget(newWidget, newSlot) as _TableViewCellElement;
      } else {
        // because we update children in [didChangeDependencies],
        // we might end up accidentally updating an inactive child before it is removed,
        // so we just skip those ones in debug mode as to not trigger an assertion
        if (!kDebugMode || child.debugIsActive) {
          updateSlotForChild(child, newSlot);
          child.update(newWidget);
          assert(child.widget == newWidget);
        }
      }

      leftoverChildren.remove(columnKey);
    }
  }
}

class _RenderTableViewRow extends RenderBox {
  _RenderTableViewRow()
      : _usePlaceholderLayers = false,
        _fixedRowHeight = false;

  final children = <Key, RenderBox>{};

  bool _usePlaceholderLayers;

  bool _fixedRowHeight;

  Key? _foregroundColumnKey;

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

  set fixedRowHeight(bool fixedRowHeight) {
    if (_fixedRowHeight != fixedRowHeight) {
      _fixedRowHeight = fixedRowHeight;
      markNeedsLayoutForSizedByParentChange();
    }
  }

  set foregroundColumnKey(Key? foregroundColumnKey) {
    if (_foregroundColumnKey != foregroundColumnKey) {
      _foregroundColumnKey = foregroundColumnKey;
      markNeedsPaint();
    }
  }

  @override
  bool get sizedByParent => _fixedRowHeight;

  void insert(RenderBox child, _TableCellSlot slot) {
    children[slot.key] = child;
    child.parentData = _TableViewCellParentData(
      width: slot.width,
      scrollable: slot.scrolled,
      position: slot.position,
    );

    adoptChild(child);
  }

  void move(RenderBox child, _TableCellSlot oldSlot, _TableCellSlot newSlot) {
    if (oldSlot.key != newSlot.key) {
      final removedChild = children.remove(oldSlot.key);
      assert(identical(child, removedChild));

      children[newSlot.key] = child;
    }

    final parentData = child.parentData as _TableViewCellParentData;
    if (parentData.width != newSlot.width ||
        parentData.scrollable != newSlot.scrolled ||
        parentData.position != newSlot.position) {
      parentData.width = newSlot.width;
      parentData.scrollable = newSlot.scrolled;
      parentData.position = newSlot.position;

      markNeedsLayout();
    }
  }

  void remove(RenderBox child, _TableCellSlot slot) {
    final removedChild = children.remove(slot.key);
    assert(removedChild == child);
    dropChild(child);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) =>
      children.values.forEach(visitor);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    for (final child in children.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();

    for (final child in children.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    for (final child in children.values) {
      redepthChild(child);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => children.entries
      .map((e) => e.value.toDiagnosticsNode(name: e.key.toString()))
      .toList(growable: false);

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = .0;

    for (final child in children.values) {
      height = max(
        0,
        child.getMaxIntrinsicHeight(
            (child.parentData as _TableViewCellParentData).width),
      );
    }

    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = .0;

    for (final child in children.values) {
      height = max(
        0,
        child.getMinIntrinsicHeight(
            (child.parentData as _TableViewCellParentData).width),
      );
    }

    return height;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  void performLayout() {
    final computeHeight = constraints.maxHeight.isInfinite;

    final minHeight =
        computeHeight ? constraints.minHeight : constraints.maxHeight;
    final maxHeight =
        computeHeight ? constraints.maxHeight : constraints.maxHeight;

    var determinedHeight = computeHeight ? .0 : constraints.maxHeight;

    for (final child in children.values) {
      final parentData = child.parentData as _TableViewCellParentData;

      child.layout(
        BoxConstraints(
          minWidth: parentData.width,
          maxWidth: parentData.width,
          minHeight: minHeight,
          maxHeight: maxHeight,
        ),
        parentUsesSize: computeHeight,
      );

      if (computeHeight) {
        determinedHeight = max(determinedHeight, child.size.height);
      }
    }

    if (!sizedByParent) {
      size = Size(constraints.maxWidth, determinedHeight);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final foregroundChild = children[_foregroundColumnKey];

    if (context is TablePaintingContext) {
      final pair =
          _usePlaceholderLayers ? context.placeholder : context.regular;

      for (final child in children.values) {
        if (identical(foregroundChild, child)) continue;

        final parentData = child.parentData as _TableViewCellParentData;
        (parentData.scrollable ? pair.scrolled : pair.fixed)
            .paintChild(child, offset + parentData.offset);
      }

      if (foregroundChild != null) {
        final parentData =
            foregroundChild.parentData as _TableViewCellParentData;
        (parentData.scrollable ? pair.scrolled : pair.fixed)
            .paintChild(foregroundChild, offset + parentData.offset);
      }
    } else {
      for (final child in children.values) {
        if (identical(foregroundChild, child)) continue;

        final parentData = child.parentData as _TableViewCellParentData;
        context.paintChild(child, offset + parentData.offset);
      }

      if (foregroundChild != null) {
        final parentData =
            foregroundChild.parentData as _TableViewCellParentData;
        context.paintChild(foregroundChild, offset + parentData.offset);
      }
    }
  }

  RenderTableSectionMixin? get _nearestTableSectionAncestor {
    var node = parent;
    while (node != null) {
      if (node is RenderTableSectionMixin) {
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

    for (final child in children.values) {
      final childParentData = child.parentData! as _TableViewCellParentData;
      if ((!childParentData.scrollable ||
              (scrolledClipPath?.contains(position) ?? true)) &&
          result.addWithPaintOffset(
            offset: childParentData.offset,
            position: position,
            hitTest: (BoxHitTestResult result, Offset transformed) {
              assert(transformed == position - childParentData.offset);
              return child.hitTest(result, position: transformed);
            },
          )) {
        return true;
      }
    }

    return false;
  }

  static bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'material_table_view table row widget does not support intrinsic width at the moment.'
          ' Feel free to leave your feedback on the issue tracker.',
        );
      }
      return true;
    }());

    return true;
  }
}

class _TableViewCellParentData extends BoxParentData {
  _TableViewCellParentData({
    required this.width,
    required this.scrollable,
    required double position,
  }) {
    offset = Offset(position, 0);
  }

  double width;

  bool scrollable;

  double get position => offset.dx;

  set position(double position) => offset = Offset(position, offset.dy);
}

class _TableViewCell extends Widget {
  final TableCellBuilder cellBuilder;
  final int index;

  const _TableViewCell({
    super.key,
    required this.cellBuilder,
    required this.index,
  });

  @override
  Element createElement() => _TableViewCellElement(this);
}

class _TableViewCellElement extends ComponentElement {
  _TableViewCellElement(super.widget);

  @override
  void update(covariant _TableViewCell newWidget) {
    final oldWidget = widget as _TableViewCell;

    super.update(newWidget);

    if (!identical(oldWidget.cellBuilder, newWidget.cellBuilder) ||
        oldWidget.index != newWidget.index) {
      rebuild(force: true);
    }
  }

  @override
  Widget build() {
    final widget = super.widget as _TableViewCell;
    return widget.cellBuilder(this, widget.index);
  }
}
