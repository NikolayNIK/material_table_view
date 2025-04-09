import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_horizontal_divider.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

enum TableScaffoldSlotType {
  header,
  headerDivider,
  body,
  footer,
  footerDivider;
}

/// This widget lays out table header, body and footer.
@immutable
class TableScaffold extends RenderObjectWidget {
  const TableScaffold({
    super.key,
    required this.dividersStyle,
    required this.header,
    required this.headerHeight,
    required this.body,
    required this.footer,
    required this.footerHeight,
    required this.shrinkWrapVertical,
  });

  final ResolvedTableViewHorizontalDividersStyle dividersStyle;
  final Widget body;
  final Widget? header, footer;
  final double headerHeight, footerHeight;
  final bool shrinkWrapVertical;

  @override
  RenderObjectElement createElement() => _TableScaffoldElement(this);

  @override
  RenderTableScaffold createRenderObject(BuildContext context) =>
      RenderTableScaffold(
        headerHeight: headerHeight,
        footerHeight: footerHeight,
        headerDividerHeight: dividersStyle.header.space,
        footerDividerHeight: dividersStyle.footer.space,
        shrinkWrapVertical: shrinkWrapVertical,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableScaffold renderObject,
  ) {
    renderObject.headerHeight = headerHeight;
    renderObject.footerHeight = footerHeight;
    renderObject.headerDividerHeight = dividersStyle.header.space;
    renderObject.footerDividerHeight = dividersStyle.footer.space;
    renderObject.shrinkWrapVertical = shrinkWrapVertical;
  }
}

class _TableScaffoldElement extends RenderObjectElement {
  _TableScaffoldElement(TableScaffold super.widget);

  Element? _header, _headerDivider, _body, _footerDivider, _footer;

  @override
  RenderTableScaffold get renderObject =>
      super.renderObject as RenderTableScaffold;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_headerDivider != null) visitor(_headerDivider!);
    if (_body != null) visitor(_body!);
    if (_footerDivider != null) visitor(_footerDivider!);
    if (_footer != null) visitor(_footer!);
  }

  @override
  void forgetChild(Element child) {
    if (identical(_header, child)) _header = null;
    if (identical(_headerDivider, child)) _headerDivider = null;
    if (identical(_body, child)) _body = null;
    if (identical(_footerDivider, child)) _footerDivider = null;
    if (identical(_footer, child)) _footer = null;

    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    _updateChildren();
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);

    _updateChildren();
  }

  void _updateChildren() {
    final widget = this.widget as TableScaffold;

    _header = updateChild(_header, widget.header, TableScaffoldSlotType.header);

    _headerDivider = updateChild(
      _headerDivider,
      _header == null || !widget.dividersStyle.header.enabled
          ? null
          : TableHorizontalDivider(style: widget.dividersStyle.header),
      TableScaffoldSlotType.headerDivider,
    );

    _body = updateChild(_body, widget.body, TableScaffoldSlotType.body);

    _footerDivider = updateChild(
      _footerDivider,
      widget.footer == null || !widget.dividersStyle.footer.enabled
          ? null
          : TableHorizontalDivider(style: widget.dividersStyle.footer),
      TableScaffoldSlotType.footerDivider,
    );

    _footer = updateChild(_footer, widget.footer, TableScaffoldSlotType.footer);
  }

  @override
  void insertRenderObjectChild(
    RenderBox child,
    TableScaffoldSlotType slot,
  ) {
    switch (slot) {
      case TableScaffoldSlotType.header:
        renderObject.header = child;
        break;
      case TableScaffoldSlotType.headerDivider:
        renderObject.headerDivider = child;
        break;
      case TableScaffoldSlotType.body:
        renderObject.body = child;
        break;
      case TableScaffoldSlotType.footer:
        renderObject.footer = child;
        break;
      case TableScaffoldSlotType.footerDivider:
        renderObject.footerDivider = child;
        break;
    }
  }

  @override
  void removeRenderObjectChild(
    RenderBox child,
    TableScaffoldSlotType slot,
  ) {
    switch (slot) {
      case TableScaffoldSlotType.header:
        assert(identical(renderObject.header, child));
        renderObject.header = null;
        break;
      case TableScaffoldSlotType.headerDivider:
        assert(identical(renderObject.headerDivider, child));
        renderObject.headerDivider = null;
        break;
      case TableScaffoldSlotType.body:
        assert(identical(renderObject.body, child));
        renderObject.body = null;
        break;
      case TableScaffoldSlotType.footer:
        assert(identical(renderObject.footer, child));
        renderObject.footer = null;
        break;
      case TableScaffoldSlotType.footerDivider:
        assert(identical(renderObject.footerDivider, child));
        renderObject.footerDivider = null;
        break;
    }
  }

  @override
  void moveRenderObjectChild(
    RenderBox child,
    TableScaffoldSlotType oldSlot,
    TableScaffoldSlotType newSlot,
  ) =>
      throw UnsupportedError(
          'TableViewLayout does not support moving children between slots');
}

class RenderTableScaffold extends RenderBox {
  RenderTableScaffold({
    required double headerHeight,
    required double footerHeight,
    required double headerDividerHeight,
    required double footerDividerHeight,
    required bool shrinkWrapVertical,
  })  : _headerHeight = headerHeight,
        _footerHeight = footerHeight,
        _headerDividerHeight = headerDividerHeight,
        _footerDividerHeight = footerDividerHeight,
        _shrinkWrapVertical = shrinkWrapVertical;

  RenderBox? _header, _headerDivider, _body, _footerDivider, _footer;

  bool _shrinkWrapVertical;

  RenderBox? get header => _header;

  RenderBox? get headerDivider => _headerDivider;

  RenderBox? get body => _body;

  RenderBox? get footerDivider => _footerDivider;

  RenderBox? get footer => _footer;

  bool get shrinkWrapVertical => _shrinkWrapVertical;

  set header(RenderBox? newRO) {
    final old = _header;
    if (old != null) dropChild(old);
    _header = newRO;
    if (newRO != null) adoptChild(newRO);
  }

  set headerDivider(RenderBox? newRO) {
    final old = _headerDivider;
    if (old != null) dropChild(old);
    _headerDivider = newRO;
    if (newRO != null) adoptChild(newRO);
  }

  set body(RenderBox? newRO) {
    final old = _body;
    if (old != null) dropChild(old);
    _body = newRO;
    if (newRO != null) adoptChild(newRO);
  }

  set footerDivider(RenderBox? newRO) {
    final old = _footerDivider;
    if (old != null) dropChild(old);
    _footerDivider = newRO;
    if (newRO != null) adoptChild(newRO);
  }

  set footer(RenderBox? newRO) {
    final old = _footer;
    if (old != null) dropChild(old);
    _footer = newRO;
    if (newRO != null) adoptChild(newRO);
  }

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

  set shrinkWrapVertical(bool value) {
    if (_shrinkWrapVertical != value) {
      _shrinkWrapVertical = value;
      markNeedsLayoutForSizedByParentChange();
    }
  }

  @override
  bool get sizedByParent => !_shrinkWrapVertical;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (header != null) visitor(header!);
    if (headerDivider != null) visitor(headerDivider!);
    if (body != null) visitor(body!);
    if (footerDivider != null) visitor(footerDivider!);
    if (footer != null) visitor(footer!);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    if (header != null) header!.attach(owner);
    if (headerDivider != null) headerDivider!.attach(owner);
    if (body != null) body!.attach(owner);
    if (footerDivider != null) footerDivider!.attach(owner);
    if (footer != null) footer!.attach(owner);
  }

  @override
  void detach() {
    super.detach();

    if (header != null) header!.detach();
    if (headerDivider != null) headerDivider!.detach();
    if (body != null) body!.detach();
    if (footerDivider != null) footerDivider!.detach();
    if (footer != null) footer!.detach();
  }

  @override
  set size(Size size) {
    // More helpful message for a subset of Flutters assertion that would have
    // triggered shortly after anyways
    assert(
      size.height.isFinite || _shrinkWrapVertical || size.width.isInfinite,
      'TableView object was given an infinite height during layout.'
      ' Consider setting `shrinkWrapVertical` to `true` to make the table calculate its own height.'
      ' Also consider using `SliverTableView` instead.'
      ' Please refer to the documentation for more details.',
    );

    super.size = size;
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    var height = constraints.maxHeight;

    final header = this.header;
    final headerDivider = this.headerDivider;
    final body = this.body;
    final footerDivider = this.footerDivider;
    final footer = this.footer;

    final headerHeight = header == null ? .0 : this.headerHeight;
    final headerDividerHeight =
        headerDivider == null ? .0 : this.headerDividerHeight;
    final footerHeight = footer == null ? .0 : this.footerHeight;
    final footerDividerHeight =
        footerDivider == null ? .0 : this.footerDividerHeight;

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

    if (shrinkWrapVertical) {
      if (body == null) {
        height = headerHeight +
            headerDividerHeight +
            footerDividerHeight +
            footerHeight;
      } else {
        body.layout(
          parentUsesSize: true,
          BoxConstraints(
            minWidth: width,
            maxWidth: width,
            minHeight: 0,
            maxHeight: height.isInfinite
                ? double.infinity
                : height -
                    headerHeight -
                    headerDividerHeight -
                    footerHeight -
                    footerDividerHeight,
          ),
        );

        (body.parentData as BoxParentData).offset =
            Offset(0, headerHeight + headerDividerHeight);

        height = headerHeight +
            headerDividerHeight +
            body.size.height +
            footerDividerHeight +
            footerHeight;
      }

      size = Size(width, height);
    } else {
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
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintChild(context, offset, footer);
    _paintChild(context, offset, body);
    _paintChild(context, offset, header);
    _paintChild(context, offset, footerDivider);
    _paintChild(context, offset, headerDivider);
  }

  void _paintChild(
    PaintingContext context,
    Offset offset,
    RenderBox? child,
  ) {
    if (child == null) return;

    context.paintChild(
      child,
      offset + (child.parentData as BoxParentData).offset,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_hitTestChild(result, position, header)) {
      return true;
    }

    if (_hitTestChild(result, position, body)) {
      return true;
    }

    if (_hitTestChild(result, position, footer)) {
      return true;
    }

    return false;
  }

  bool _hitTestChild(
    BoxHitTestResult result,
    Offset position,
    RenderBox? child,
  ) {
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
