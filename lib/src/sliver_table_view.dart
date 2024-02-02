import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/sliver_table_view_body.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_column_resolve_layout_extension.dart';
import 'package:material_table_view/src/table_horizontal_divider.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_scrollbar.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_view.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

/// This is a sliver variant of the [TableView] widget.
/// This variant is scrolled vertically by an outside [Scrollable]
/// (e.g. [CustomScrollView]), thus allowing it to be used alongside
/// other slivers, including other instances of [SliverTableView].
///
/// Horizontal scrolling is managed by this widget itself.
class SliverTableView extends TableView {
  SliverTableView.builder({
    super.key,
    super.style,
    required super.rowCount,
    required super.rowHeight,
    required super.columns,
    this.horizontalScrollController,
    required super.rowBuilder,
    super.placeholderBuilder,
    super.placeholderShade,
    super.bodyContainerBuilder,
    super.headerBuilder,
    super.headerHeight,
    super.footerBuilder,
    super.footerHeight,
    super.minScrollableWidth,
    super.minScrollableWidthRatio,
    @Deprecated(
        'Setting this property prevents default behavior of leaving space for scrollbars.'
        ' Use scrollPadding property of TableViewStyle instead.')
    super.scrollPadding,
  }) : super.builder();

  /// A scroll controller used for the horizontal scrolling of the table.
  final ScrollController? horizontalScrollController;

  @override
  State<TableView> createState() => _SliverTableViewState();
}

class _SliverTableViewState extends State<SliverTableView>
    implements TableColumnControlsControllable<SliverTableView> {
  late ScrollController _horizontalScrollController;
  late ValueNotifier<double> _horizontalStickyOffset;

  @override
  Key? get key => widget.key;

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

    final scrollPadding = widget.scrollPadding ?? style.scrollPadding;

    final headerHeight = (widget.headerBuilder == null
        ? .0
        : widget.headerHeight + style.dividers.horizontal.header.space);
    final footerHeight = (widget.footerBuilder == null
        ? .0
        : widget.footerHeight + style.dividers.horizontal.footer.space);

    final scrollbarOffset = Offset(0, -footerHeight);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = widget.columns.resolveLayout(
            constraints.crossAxisExtent - scrollPadding.horizontal);
        return _SliverPassthrough(
          minHeight: scrollPadding.bottom + headerHeight + footerHeight,
          maxHeight: widget.rowCount * widget.rowHeight +
              scrollPadding.vertical +
              headerHeight +
              footerHeight,
          builder: (context, sliverBuilder, verticalScrollOffsetPixels) =>
              Transform.translate(
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
                  axisDirection: AxisDirection.right,
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
                      width: constraints.crossAxisExtent,
                      columns: columns,
                      horizontalOffset: position,
                      stickyHorizontalOffset: _horizontalStickyOffset,
                      minScrollableWidthRatio: widget.minScrollableWidthRatio ??
                          style.minScrollableWidthRatio,
                      minScrollableWidth: widget.minScrollableWidth,
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
                                    context, contentBuilder),
                              ),
                            ),
                            TableHorizontalDivider(
                              style: style.dividers.horizontal.header,
                            ),
                          ],
                          Expanded(
                            child: ClipRect(
                              child: TableSection(
                                rowHeight: widget.rowHeight,
                                verticalOffset: ViewportOffset.fixed(
                                    verticalScrollOffsetPixels),
                                placeholderShade: widget.placeholderShade,
                                child: sliverBuilder(
                                  sliver: SliverPadding(
                                    padding: EdgeInsets.only(
                                      top: scrollPadding.top,
                                      bottom: scrollPadding.bottom,
                                    ),
                                    sliver: SliverTableViewBody(
                                      rowHeight: widget.rowHeight,
                                      rowCount: widget.rowCount,
                                      rowBuilder: widget.rowBuilder,
                                      placeholderBuilder:
                                          widget.placeholderBuilder,
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
                                    context, contentBuilder),
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
                  top,
                ),
              ),
            ),
          );
        },
      );
}

class _BoxToSliverAdapter extends SingleChildRenderObjectWidget {
  _BoxToSliverAdapter({
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
