import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/optional_wrap.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/sliver_table_body.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_column_resolve_layout_extension.dart';
import 'package:material_table_view/src/table_horizontal_divider.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_scrollbar.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_section_overlay.dart';
import 'package:material_table_view/src/table_view.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

/// This is a sliver variant of the [TableView] widget.
/// This variant is scrolled vertically by an outside [Scrollable]
/// (e.g. [CustomScrollView]), thus allowing it to be used alongside
/// other slivers, including other instances of [SliverTableView].
///
/// Horizontal scrolling is managed by this widget itself.
class SliverTableView extends TableView {
  const SliverTableView.builder({
    super.key,
    super.style,
    super.controller,
    this.horizontalScrollController,
    required super.columns,
    super.textDirection,
    super.minScrollableWidth,
    super.minScrollableWidthRatio,
    super.rowReorder,
    super.addAutomaticKeepAlives,
    required super.rowCount,
    required double rowHeight,
    required super.rowBuilder,
    super.placeholderBuilder,
    super.placeholderRowBuilder,
    super.placeholderShade,
    super.bodyContainerBuilder,
    super.headerBuilder,
    super.headerHeight,
    super.footerBuilder,
    super.footerHeight,
  }) : super.builder(rowHeight: rowHeight);

  /// A scroll controller used for the horizontal scrolling of the table.
  final ScrollController? horizontalScrollController;

  @override
  double get rowHeight => super.rowHeight!;

  @override
  State<SliverTableView> createState() => _SliverTableViewState();
}

class _SliverTableViewState extends State<SliverTableView>
    implements TableColumnControlsControllable<SliverTableView> {
  late ScrollController _horizontalScrollController;
  late ValueNotifier<double> _horizontalStickyOffset;

  List<TableColumn>? _columns;

  late double _lastResolvedColumnsWidth;

  @override
  late TextDirection textDirection;

  @override
  List<TableColumn> get columns => _columns ?? widget.columns;

  @override
  ScrollController get horizontalScrollController =>
      _horizontalScrollController;

  @override
  void initState() {
    super.initState();

    _horizontalScrollController =
        widget.horizontalScrollController ?? ScrollController();
    _horizontalStickyOffset = ValueNotifier(.0);
  }

  @override
  void didUpdateWidget(covariant SliverTableView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _columns = null;
    _horizontalScrollController =
        widget.horizontalScrollController ?? _horizontalScrollController;
  }

  @override
  Widget build(BuildContext context) {
    final style = ResolvedTableViewStyle.of(
      context,
      style: widget.style,
      sliver: true,
    );

    final scrollPadding = style.scrollPadding;

    final headerHeight = (widget.headerBuilder == null
        ? .0
        : widget.headerHeight + style.dividers.horizontal.header.space);
    final footerHeight = (widget.footerBuilder == null
        ? .0
        : widget.footerHeight + style.dividers.horizontal.footer.space);

    final scrollbarOffset = Offset(0, -footerHeight);

    textDirection = widget.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;

    return _SliverPassthrough(
      minHeight: scrollPadding.bottom + headerHeight + footerHeight,
      maxHeight: widget.rowCount * widget.rowHeight +
          scrollPadding.vertical +
          headerHeight +
          footerHeight,
      builder: (context, sliverBuilder, width, verticalScrollOffsetPixels) {
        final columns = _columns != null && width == _lastResolvedColumnsWidth
            ? _columns!
            : _columns =
                widget.columns.resolveLayout(width - scrollPadding.horizontal);

        _lastResolvedColumnsWidth = width;

        return Transform.translate(
          offset: scrollbarOffset,
          transformHitTests: false,
          child: TableScrollbar(
            controller: _horizontalScrollController,
            style: style.scrollbars.horizontal,
            child: Transform.translate(
              offset: -scrollbarOffset,
              transformHitTests: false,
              child: Scrollable(
                controller: _horizontalScrollController,
                axisDirection: textDirectionToAxisDirection(textDirection),
                viewportBuilder: (context, position) =>
                    ScrollDimensionsApplicator(
                  position: _horizontalScrollController.position,
                  axis: Axis.horizontal,
                  scrollExtent: columns.fold<double>(
                          .0,
                          (previousValue, element) =>
                              previousValue + element.width) +
                      scrollPadding.horizontal,
                  child: TableContentLayout(
                    verticalDividersStyle: style.dividers.vertical,
                    width: width,
                    fixedRowHeight: true,
                    columns: columns,
                    horizontalOffset: position,
                    stickyHorizontalOffset: _horizontalStickyOffset,
                    minScrollableWidthRatio: widget.minScrollableWidthRatio ??
                        style.minScrollableWidthRatio,
                    minScrollableWidth: widget.minScrollableWidth,
                    textDirection: textDirection,
                    scrollPadding: scrollPadding,
                    child: Column(
                      children: [
                        if (widget.headerBuilder != null) ...[
                          SizedBox(
                            height: widget.headerHeight,
                            child: TableSection(
                              verticalOffset: null,
                              rowHeight: widget.headerHeight,
                              placeholderShade: null,
                              child: widget.headerBuilder!(
                                  context, headerFooterContentBuilder),
                            ),
                          ),
                          TableHorizontalDivider(
                            style: style.dividers.horizontal.header,
                          ),
                        ],
                        Expanded(
                          child: widget.bodyContainerBuilder(
                            context,
                            ClipRect(
                              child: TableSection(
                                rowHeight: widget.rowHeight,
                                verticalOffset: ViewportOffset.fixed(
                                    verticalScrollOffsetPixels),
                                placeholderShade: widget.placeholderShade,
                                child: OptionalWrap(
                                  builder: widget.rowReorder == null
                                      ? null
                                      : (context, child) =>
                                          TableSectionOverlay(child: child),
                                  child: sliverBuilder(
                                    sliver: SliverPadding(
                                      padding: EdgeInsets.only(
                                        top: scrollPadding.top,
                                        bottom: scrollPadding.bottom,
                                      ),
                                      sliver: SliverTableViewBody(
                                        rowHeight: widget.rowHeight,
                                        rowHeightBuilder: null,
                                        rowPrototype: null,
                                        rowCount: widget.rowCount,
                                        rowBuilder: widget.rowBuilder,
                                        rowReorder: widget.rowReorder,
                                        placeholderBuilder:
                                            widget.placeholderBuilder,
                                        placeholderRowBuilder:
                                            widget.placeholderRowBuilder,
                                        useHigherScrollable: true,
                                        addAutomaticKeepAlives:
                                            widget.addAutomaticKeepAlives,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.footerBuilder != null) ...[
                          TableHorizontalDivider(
                            style: style.dividers.horizontal.footer,
                          ),
                          SizedBox(
                            height: widget.footerHeight,
                            child: TableSection(
                              verticalOffset: null,
                              rowHeight: widget.footerHeight,
                              placeholderShade: null,
                              child: widget.footerBuilder!(
                                  context, headerFooterContentBuilder),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// This widget allows inserting box widget amids the sliver layout protocol
/// and then continue sliver layout protocol as if nothing happened.
class _SliverPassthrough extends StatelessWidget {
  const _SliverPassthrough({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  final double minHeight;
  final double maxHeight;
  final Widget Function(
    BuildContext context,
    Widget Function({
      required Widget sliver,
    }) sliverBuilder,
    double width,
    double verticalScrollOffsetPixels,
  ) builder;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          assert(constraints.axis == Axis.vertical);

          var boxHeight = min(constraints.remainingPaintExtent,
              maxHeight - constraints.scrollOffset);

          if (boxHeight <= 0) {
            return SliverPadding(
              padding: EdgeInsets.only(bottom: maxHeight),
            );
          }

          var top = constraints.scrollOffset;
          var bottom = maxHeight - constraints.scrollOffset - boxHeight;

          if (boxHeight < minHeight) {
            final diff = minHeight - boxHeight;
            top = max(0, top - diff);
            boxHeight = minHeight;
          }

          return SliverPadding(
            padding: EdgeInsets.only(
              top: top,
              bottom: bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                height: boxHeight,
                child: builder(
                  context,
                  ({required sliver}) => _BoxToSliverAdapter(
                    constraints: constraints,
                    child: sliver,
                  ),
                  constraints.crossAxisExtent,
                  top,
                ),
              ),
            ),
          );
        },
      );
}

class _BoxToSliverAdapter extends SingleChildRenderObjectWidget {
  const _BoxToSliverAdapter({
    required this.constraints,
    required super.child,
  });

  final SliverConstraints constraints;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBoxToSliver(
        constraints: constraints,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderBoxToSliver renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject.sliverConstraints = constraints;
  }
}

class _RenderBoxToSliver extends RenderBox
    with RenderObjectWithChildMixin<RenderSliver> {
  _RenderBoxToSliver({
    required SliverConstraints constraints,
  }) : _constraints = constraints;

  SliverConstraints _constraints;

  set sliverConstraints(SliverConstraints constraints) {
    if (_constraints != constraints) {
      _constraints = constraints;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    child!.layout(_constraints);
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(child!, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child!.hitTest(
        SliverHitTestResult.wrap(result),
        mainAxisPosition: position.dy,
        crossAxisPosition: position.dx,
      );
}
