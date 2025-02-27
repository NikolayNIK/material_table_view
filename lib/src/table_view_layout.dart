import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_horizontal_divider.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

/// This widget lays out table header, body and footer.
@immutable
class TableViewLayout extends SlottedMultiChildRenderObjectWidget<
    TableViewLayoutSlotType, RenderBox> {
  const TableViewLayout({
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
  RenderTableViewLayout createRenderObject(BuildContext context) =>
      RenderTableViewLayout(
        headerHeight: headerHeight,
        footerHeight: footerHeight,
        headerDividerHeight: dividersStyle.header.space,
        footerDividerHeight: dividersStyle.footer.space,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableViewLayout renderObject,
  ) {
    renderObject.headerHeight = headerHeight;
    renderObject.footerHeight = footerHeight;
    renderObject.headerDividerHeight = dividersStyle.header.space;
    renderObject.footerDividerHeight = dividersStyle.footer.space;
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

class RenderTableViewLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<TableViewLayoutSlotType, RenderBox> {
  RenderTableViewLayout({
    required double headerHeight,
    required double footerHeight,
    required double headerDividerHeight,
    required double footerDividerHeight,
  })  : _headerHeight = headerHeight,
        _footerHeight = footerHeight,
        _headerDividerHeight = headerDividerHeight,
        _footerDividerHeight = footerDividerHeight;

  double _headerHeight, _footerHeight;
  double _headerDividerHeight, _footerDividerHeight;

  double get headerHeight => _headerHeight;

  double get footerHeight => _footerHeight;

  double get headerDividerHeight => _headerDividerHeight;

  double get footerDividerHeight => _footerDividerHeight;

  set headerHeight(double value) {
    if (_headerHeight != value) {
      _headerHeight = value;
      markNeedsLayout();
    }
  }

  set footerHeight(double value) {
    if (_footerHeight != value) {
      _footerHeight = value;
      markNeedsLayout();
    }
  }

  set headerDividerHeight(double value) {
    if (_headerDividerHeight != value) {
      _headerDividerHeight = value;
      markNeedsLayout();
    }
  }

  set footerDividerHeight(double value) {
    if (_footerDividerHeight != value) {
      _footerDividerHeight = value;
      markNeedsLayout();
    }
  }

  @override
  bool get sizedByParent => true;

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

    if (header != null) {
      header.layout(
        BoxConstraints.tightFor(
          width: width,
          height: headerHeight,
        ),
      );

      (header.parentData as BoxParentData).offset = Offset.zero;
    }

    if (headerDivider != null) {
      headerDivider.layout(
        BoxConstraints.tightFor(width: width, height: headerDividerHeight),
      );

      (headerDivider.parentData as BoxParentData).offset =
          Offset(0, headerHeight);
    }

    if (footer != null) {
      footer.layout(
        BoxConstraints.tightFor(
          width: width,
          height: footerHeight,
        ),
      );

      (footer.parentData as BoxParentData).offset =
          Offset(0, height - footerHeight);
    }

    if (footerDivider != null) {
      footerDivider.layout(
        BoxConstraints.tightFor(
          width: width,
          height: footerDividerHeight,
        ),
      );

      (footerDivider.parentData as BoxParentData).offset =
          Offset(0, height - footerHeight - footerDividerHeight);
    }

    if (body != null) {
      body.layout(
        BoxConstraints.tightFor(
          width: width,
          height: height -
              headerHeight -
              headerDividerHeight -
              footerHeight -
              footerDividerHeight,
        ),
      );

      (body.parentData as BoxParentData).offset =
          Offset(0, headerHeight + headerDividerHeight);
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
