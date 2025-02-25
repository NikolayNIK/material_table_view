import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_horizontal_divider.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

/// This widget lays out table header, body and footer.
@immutable
class TableViewLayout extends SlottedMultiChildRenderObjectWidget<
    TableViewLayoutSlotType, RenderBox> {
  const TableViewLayout.box({
    super.key,
    required this.dividersStyle,
    required this.header,
    required this.headerHeight,
    required this.body,
    required this.footer,
    required this.footerHeight,
  });

  final ResolvedTableViewHorizontalDividersStyle dividersStyle;
  final Widget body;
  final Widget? header, footer;
  final double headerHeight, footerHeight;

  @override
  RenderSliverTableViewLayout createRenderObject(BuildContext context) =>
      RenderSliverTableViewLayout(
        headerHeight: headerHeight,
        footerHeight: footerHeight,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverTableViewLayout renderObject,
  ) {
    renderObject.headerHeight = headerHeight;
    renderObject.footerHeight = footerHeight;
  }

  @override
  Iterable<TableViewLayoutSlotType> get slots => TableViewLayoutSlotType.values;

  @override
  Widget? childForSlot(TableViewLayoutSlotType slot) {
    switch (slot) {
      case TableViewLayoutSlotType.header:
        return header;
      case TableViewLayoutSlotType.headerDivider:
        return header == null
            ? null
            : TableHorizontalDivider(style: dividersStyle.header);
      case TableViewLayoutSlotType.body:
        return body;
      case TableViewLayoutSlotType.footer:
        return footer;
      case TableViewLayoutSlotType.footerDivider:
        return footer == null
            ? null
            : TableHorizontalDivider(style: dividersStyle.footer);
    }
  }
}

enum TableViewLayoutSlotType {
  header,
  headerDivider,
  body,
  footer,
  footerDivider;
}

class RenderSliverTableViewLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<TableViewLayoutSlotType, RenderBox> {
  RenderSliverTableViewLayout(
      {required double headerHeight, required double footerHeight})
      : _headerInnerHeight = headerHeight,
        _footerInnerHeight = footerHeight;

  double _headerInnerHeight, _footerInnerHeight;

  @override
  bool get sizedByParent => true;

  set headerHeight(double value) {
    if (_headerInnerHeight != value) {
      _headerInnerHeight = value;
      markNeedsLayout();
    }
  }

  set footerHeight(double value) {
    if (_footerInnerHeight != value) {
      _footerInnerHeight = value;
      markNeedsLayout();
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    double headerOuterHeight = 0;
    {
      final child = childForSlot(TableViewLayoutSlotType.header);
      if (child != null) {
        final headerHeight = _headerInnerHeight;

        child.layout(
          BoxConstraints.tightFor(
            width: width,
            height: headerHeight,
          ),
        );

        (child.parentData as BoxParentData).offset = Offset.zero;

        headerOuterHeight += headerHeight;

        final divider = childForSlot(TableViewLayoutSlotType.headerDivider);
        if (divider != null) {
          divider.layout(
            BoxConstraints(
              minWidth: width,
              maxWidth: width,
              minHeight: 0,
              maxHeight: height - headerOuterHeight,
            ),
            parentUsesSize: true,
          );

          (divider.parentData as BoxParentData).offset =
              Offset(0, headerHeight);

          headerOuterHeight += divider.size.height;
        }
      }
    }

    double footerOuterHeight = 0;
    {
      final child = childForSlot(TableViewLayoutSlotType.footer);
      if (child != null) {
        final footerHeight = _footerInnerHeight;

        child.layout(
          BoxConstraints.tightFor(
            width: width,
            height: footerHeight,
          ),
        );

        (child.parentData as BoxParentData).offset =
            Offset(0, height - footerHeight);

        footerOuterHeight += footerHeight;

        final divider = childForSlot(
          TableViewLayoutSlotType.footerDivider,
        );

        if (divider != null) {
          divider.layout(
            BoxConstraints(
              minWidth: width,
              maxWidth: width,
              minHeight: 0,
              maxHeight:
              height - headerOuterHeight - footerOuterHeight,
            ),
            parentUsesSize: true,
          );

          footerOuterHeight += divider.size.height;

          (divider.parentData as BoxParentData).offset =
              Offset(0, height - footerOuterHeight);
        }
      }
    }

    {
      final child = childForSlot(TableViewLayoutSlotType.body);
      if (child != null) {
        child.layout(
          BoxConstraints.tightFor(
            width: width,
            height:
            height - headerOuterHeight - footerOuterHeight,
          ),
        );

        (child.parentData as BoxParentData).offset =
            Offset(0, headerOuterHeight);
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintChild(context, offset, TableViewLayoutSlotType.footer);
    _paintChild(context, offset, TableViewLayoutSlotType.body);
    _paintChild(context, offset, TableViewLayoutSlotType.header);
    _paintChild(context, offset, TableViewLayoutSlotType.footerDivider);
    _paintChild(context, offset, TableViewLayoutSlotType.headerDivider);
  }

  void _paintChild(
    PaintingContext context,
    Offset offset,
    TableViewLayoutSlotType childSlot,
  ) {
    final child = childForSlot(childSlot);
    if (child == null) return;

    context.paintChild(
      child,
      offset + (child.parentData as BoxParentData).offset,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_hitTestChild(result, position, TableViewLayoutSlotType.header)) {
      return true;
    }

    if (_hitTestChild(result, position, TableViewLayoutSlotType.body)) {
      return true;
    }

    if (_hitTestChild(result, position, TableViewLayoutSlotType.footer)) {
      return true;
    }

    return false;
  }

  bool _hitTestChild(
    BoxHitTestResult result,
    Offset position,
    TableViewLayoutSlotType childSlot,
  ) {
    final child = childForSlot(childSlot);
    if (child == null) return false;

    return result.addWithPaintOffset(
      position: position,
      offset: (child.parentData as BoxParentData).offset,
      hitTest: (result, position) => child.hitTest(
        result,
        position: position,
      ),
    );
  }
}
