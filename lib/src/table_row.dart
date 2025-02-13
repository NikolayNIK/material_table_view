import 'dart:math';

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

typedef _TableCellSlot = Object?;

class _TableViewRowElement extends RenderObjectElement {
  _TableViewRowElement(TableViewRow super.widget);

  static const _TableCellSlot _slot = null;

  late List<Element> fixedChildren = List.empty();
  late List<Element> scrolledChildren = List.empty();

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
    fixedChildren.forEach(visitor);
    scrolledChildren.forEach(visitor);
  }

  @override
  void mount(Element? parent, _TableCellSlot newSlot) {
    super.mount(parent, newSlot);

    markNeedsBuild();
    rebuild();
  }

  @override
  void update(covariant RenderObjectWidget newWidget) {
    super.update(newWidget);

    markNeedsBuild();
    rebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _updateRenderObject(TableContentLayout.of(this));
  }

  @override
  void insertRenderObjectChild(RenderBox child, _TableCellSlot? slot) {
    renderObject.insert(child);
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    covariant _TableCellSlot oldSlot,
    covariant _TableCellSlot newSlot,
  ) {
    // do we even care?
  }

  @override
  void removeRenderObjectChild(
    covariant RenderBox child,
    covariant _TableCellSlot slot,
  ) {
    renderObject.remove(child);
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
  }

  void _updateChildren(TableContentLayoutData data) {
    // TODO
    //  Find a way to somehow avoid running this algorithm for each visible row,
    //  since all of them should have the same result.

    final scrolledOldChildren = scrolledChildren;
    final scrolledNewWidgets =
        _buildChildWidgetList(data.scrollableColumns, true);
    final scrolledNewChildren =
        List<Element?>.filled(scrolledNewWidgets.length, null);
    int scrolledNewChildrenTop = 0;
    int scrolledOldChildrenTop = 0;
    int scrolledNewChildrenBottom = scrolledNewWidgets.length - 1;
    int scrolledOldChildrenBottom = scrolledOldChildren.length - 1;

    final fixedOldChildren = fixedChildren;
    final fixedNewWidgets = _buildChildWidgetList(data.fixedColumns, false);
    final fixedNewChildren =
        List<Element?>.filled(fixedNewWidgets.length, null);
    int fixedNewChildrenTop = 0;
    int fixedOldChildrenTop = 0;
    int fixedNewChildrenBottom = fixedNewWidgets.length - 1;
    int fixedOldChildrenBottom = fixedOldChildren.length - 1;

    // Update the top of the list.
    while ((fixedOldChildrenTop <= fixedOldChildrenBottom) &&
        (fixedNewChildrenTop <= fixedNewChildrenBottom)) {
      final Element oldChild = fixedOldChildren[fixedOldChildrenTop];
      final Widget newWidget = fixedNewWidgets[fixedNewChildrenTop];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      fixedNewChildren[fixedNewChildrenTop] = newChild;
      fixedNewChildrenTop += 1;
      fixedOldChildrenTop += 1;
    }

    while ((scrolledOldChildrenTop <= scrolledOldChildrenBottom) &&
        (scrolledNewChildrenTop <= scrolledNewChildrenBottom)) {
      final Element oldChild = scrolledOldChildren[scrolledOldChildrenTop];
      final Widget newWidget = scrolledNewWidgets[scrolledNewChildrenTop];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      scrolledNewChildren[scrolledNewChildrenTop] = newChild;
      scrolledNewChildrenTop += 1;
      scrolledOldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((fixedOldChildrenTop <= fixedOldChildrenBottom) &&
        (fixedNewChildrenTop <= fixedNewChildrenBottom)) {
      final Element oldChild = fixedOldChildren[fixedOldChildrenBottom];
      final Widget newWidget = fixedNewWidgets[fixedNewChildrenBottom];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }

      fixedOldChildrenBottom -= 1;
      fixedNewChildrenBottom -= 1;
    }

    while ((scrolledOldChildrenTop <= scrolledOldChildrenBottom) &&
        (scrolledNewChildrenTop <= scrolledNewChildrenBottom)) {
      final Element oldChild = scrolledOldChildren[scrolledOldChildrenBottom];
      final Widget newWidget = scrolledNewWidgets[scrolledNewChildrenBottom];
      if (!Widget.canUpdate(oldChild.widget, newWidget)) {
        break;
      }

      scrolledOldChildrenBottom -= 1;
      scrolledNewChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    Map<Key, Element>? oldKeyedChildren;

    if (fixedOldChildrenTop <= fixedOldChildrenBottom) {
      oldKeyedChildren = <Key, Element>{};
      while (fixedOldChildrenTop <= fixedOldChildrenBottom) {
        final Element oldChild = fixedOldChildren[fixedOldChildrenTop];
        if (oldChild.widget.key != null) {
          oldKeyedChildren[oldChild.widget.key!] = oldChild;
        } else {
          deactivateChild(oldChild);
        }

        fixedOldChildrenTop += 1;
      }
    }

    if (scrolledOldChildrenTop <= scrolledOldChildrenBottom) {
      oldKeyedChildren ??= <Key, Element>{};
      while (scrolledOldChildrenTop <= scrolledOldChildrenBottom) {
        final Element oldChild = scrolledOldChildren[scrolledOldChildrenTop];
        if (oldChild.widget.key != null) {
          oldKeyedChildren[oldChild.widget.key!] = oldChild;
        } else {
          deactivateChild(oldChild);
        }

        scrolledOldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (fixedNewChildrenTop <= fixedNewChildrenBottom) {
      Element? oldChild;
      final Widget newWidget = fixedNewWidgets[fixedNewChildrenTop];
      if (oldKeyedChildren != null) {
        final Key? key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      fixedNewChildren[fixedNewChildrenTop] = newChild;
      fixedNewChildrenTop += 1;
    }

    while (scrolledNewChildrenTop <= scrolledNewChildrenBottom) {
      Element? oldChild;
      final Widget newWidget = scrolledNewWidgets[scrolledNewChildrenTop];
      if (oldKeyedChildren != null) {
        final Key? key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      scrolledNewChildren[scrolledNewChildrenTop] = newChild;
      scrolledNewChildrenTop += 1;
    }

    // We've scanned the whole list.
    assert(fixedOldChildrenTop == fixedOldChildrenBottom + 1);
    assert(fixedNewChildrenTop == fixedNewChildrenBottom + 1);
    assert(fixedNewWidgets.length - fixedNewChildrenTop ==
        fixedOldChildren.length - fixedOldChildrenTop);
    fixedNewChildrenBottom = fixedNewWidgets.length - 1;
    fixedOldChildrenBottom = fixedOldChildren.length - 1;

    assert(scrolledOldChildrenTop == scrolledOldChildrenBottom + 1);
    assert(scrolledNewChildrenTop == scrolledNewChildrenBottom + 1);
    assert(scrolledNewWidgets.length - scrolledNewChildrenTop ==
        scrolledOldChildren.length - scrolledOldChildrenTop);
    scrolledNewChildrenBottom = scrolledNewWidgets.length - 1;
    scrolledOldChildrenBottom = scrolledOldChildren.length - 1;

    // Update the bottom of the list.
    while ((fixedOldChildrenTop <= fixedOldChildrenBottom) &&
        (fixedNewChildrenTop <= fixedNewChildrenBottom)) {
      final Element oldChild = fixedOldChildren[fixedOldChildrenTop];
      final Widget newWidget = fixedNewWidgets[fixedNewChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      fixedNewChildren[fixedNewChildrenTop] = newChild;
      fixedNewChildrenTop += 1;
      fixedOldChildrenTop += 1;
    }

    while ((scrolledOldChildrenTop <= scrolledOldChildrenBottom) &&
        (scrolledNewChildrenTop <= scrolledNewChildrenBottom)) {
      final Element oldChild = scrolledOldChildren[scrolledOldChildrenTop];
      final Widget newWidget = scrolledNewWidgets[scrolledNewChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));

      final Element newChild = updateChild(oldChild, newWidget, _slot)!;
      scrolledNewChildren[scrolledNewChildrenTop] = newChild;
      scrolledNewChildrenTop += 1;
      scrolledOldChildrenTop += 1;
    }

    // Clean up any of the remaining middle nodes from the old list.
    if (oldKeyedChildren != null && oldKeyedChildren.isNotEmpty) {
      for (final Element oldChild in oldKeyedChildren.values) {
        deactivateChild(oldChild);
      }
    }

    scrolledChildren = scrolledNewChildren.cast();
    fixedChildren = fixedNewChildren.cast();
  }

  List<Widget> _buildChildWidgetList(
    TableContentColumnData data,
    bool scrolled,
  ) =>
      List.generate(
        growable: false,
        data.indices.length,
        (index) {
          final columnIndex = data.indices[index];
          final columnKey = data.keys[index];
          return _TableViewCell(
            key: columnKey,
            width: data.widths[index],
            position: data.positions[index],
            scrolled: scrolled,
            child: Builder(
              builder: (context) {
                // TODO
                //  Consider removing this Builder along with
                //  the context parameter from the public API.
                return widget.cellBuilder(context, columnIndex);
              },
            ),
          );
        },
      );
}

class _RenderTableViewRow extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _TableViewCellParentData> {
  _RenderTableViewRow()
      : _usePlaceholderLayers = false,
        _fixedRowHeight = false;

  bool _usePlaceholderLayers;

  bool _fixedRowHeight;

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

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! _TableViewCellParentData) {
      child.parentData = _TableViewCellParentData();
    }
  }

  @override
  bool get sizedByParent => _fixedRowHeight;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  double computeMaxIntrinsicHeight(double width) {
    var height = .0;

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData as _TableViewCellParentData;

      height = max(0, child.getMaxIntrinsicHeight(parentData.width));

      child = parentData.nextSibling;
    }

    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var height = .0;

    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData as _TableViewCellParentData;

      height = max(0, child.getMinIntrinsicHeight(parentData.width));

      child = parentData.nextSibling;
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

    var child = firstChild;
    while (child != null) {
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

      parentData.offset = Offset(parentData.position, 0);

      child = parentData.nextSibling;
    }

    if (!sizedByParent) {
      size = Size(constraints.maxWidth, determinedHeight);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (context is TablePaintingContext) {
      final pair =
          _usePlaceholderLayers ? context.placeholder : context.regular;

      var child = firstChild;
      while (child != null) {
        final parentData = child.parentData as _TableViewCellParentData;
        (parentData.scrollable ? pair.scrolled : pair.fixed).paintChild(
          child,
          Offset(offset.dx + parentData.position, offset.dy),
        );

        child = parentData.nextSibling;
      }
    } else {
      var child = firstChild;
      while (child != null) {
        final parentData = child.parentData as _TableViewCellParentData;
        context.paintChild(
          child,
          Offset(offset.dx + parentData.position, offset.dy),
        );

        child = parentData.nextSibling;
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

    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as _TableViewCellParentData;
      if ((!childParentData.scrollable ||
              (scrolledClipPath?.contains(position) ?? true)) &&
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
