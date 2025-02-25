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
  RenderBoxTableViewLayout createRenderObject(BuildContext context) =>
      RenderBoxTableViewLayout(
        headerHeight: headerHeight,
        footerHeight: footerHeight,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBoxTableViewLayout renderObject,
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

class RenderBoxTableViewLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<TableViewLayoutSlotType, RenderBox> {
  RenderBoxTableViewLayout(
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

    final header = childForSlot(TableViewLayoutSlotType.header);
    final headerDivider = childForSlot(TableViewLayoutSlotType.headerDivider);
    final footer = childForSlot(TableViewLayoutSlotType.footer);
    final footerDivider = childForSlot(TableViewLayoutSlotType.footerDivider);
    final body = childForSlot(TableViewLayoutSlotType.body);

    double headerOuterHeight = .0;
    double footerOuterHeight = .0;

    if (header != null) {
      final headerHeight = _headerInnerHeight;

      header.layout(
        BoxConstraints.tightFor(
          width: width,
          height: headerHeight,
        ),
      );

      (header.parentData as BoxParentData).offset = Offset.zero;

      headerOuterHeight += headerHeight;
    }

    if (headerDivider != null) {
      headerDivider.layout(
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: 0,
          maxHeight: height - headerOuterHeight,
        ),
        parentUsesSize: true,
      );

      (headerDivider.parentData as BoxParentData).offset =
          Offset(0, headerOuterHeight);

      headerOuterHeight += headerDivider.size.height;
    }

    if (footer != null) {
      final footerHeight = _footerInnerHeight;

      footer.layout(
        BoxConstraints.tightFor(
          width: width,
          height: footerHeight,
        ),
      );

      (footer.parentData as BoxParentData).offset =
          Offset(0, height - footerHeight);

      footerOuterHeight += footerHeight;
    }

    if (footerDivider != null) {
      footerDivider.layout(
        BoxConstraints(
          minWidth: width,
          maxWidth: width,
          minHeight: 0,
          maxHeight: height - headerOuterHeight - footerOuterHeight,
        ),
        parentUsesSize: true,
      );

      footerOuterHeight += footerDivider.size.height;

      (footerDivider.parentData as BoxParentData).offset =
          Offset(0, height - footerOuterHeight);
    }

    if (body != null) {
      body.layout(
        BoxConstraints.tightFor(
          width: width,
          height: height - headerOuterHeight - footerOuterHeight,
        ),
      );

      (body.parentData as BoxParentData).offset = Offset(0, headerOuterHeight);
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
