import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/determine_scroll_padding.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/sliver_table_view_body.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_placeholder_shade.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

/// Material-style widget that displays its content in a both vertically and
/// horizontally scrollable table with fixed-width freezable columns.
///
/// This widget will try to expand to the highest constraints given.
class TableView extends StatefulWidget {
  const TableView.builder({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.columns,
    this.controller,
    required this.rowBuilder,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    this.placeholderShade,
    this.bodyContainerBuilder = _defaultBodyContainerBuilder,
    this.headerBuilder,
    double? headerHeight,
    this.footerBuilder,
    double? footerHeight,
    this.minScrollableWidth,
    this.minScrollableWidthRatio = .6180339887498547,
    this.scrollPadding,
    this.showHorizontalScrollBar = true,
  })  : assert(rowCount >= 0),
        assert(rowHeight > 0),
        assert(headerHeight == null || headerHeight > 0),
        assert(footerHeight == null || footerHeight > 0),
        assert(minScrollableWidth == null || minScrollableWidth > 0),
        assert(minScrollableWidthRatio >= 0 && minScrollableWidthRatio <= 1),
        headerHeight = headerHeight ?? rowHeight,
        footerHeight = footerHeight ?? rowHeight;

  /// Count of fixed-height rows displayed in a table.
  final int rowCount;

  /// Height of each row displayed in a table.
  final double rowHeight;

  /// List of column descriptions to display in a table.
  final List<TableColumn> columns;

  /// Controller for the state of a table.
  final TableViewController? controller;

  /// A function that will be called on-demand for each row displayed
  /// in order to build a widget of a row of the table.
  ///
  /// In case of this function returning null, the corresponding row will be
  /// replaced with a placeholder. This enables additional behaviour described in a
  /// [placeholderBuilder] property.
  final TableRowBuilder rowBuilder;

  /// A function that will be called on-demand for building the placeholder
  /// row widget. It never gets called more than once per build cycle as the
  /// same widget is reused for every placeholder row built.
  ///
  /// [placeholderShade] can be used to apply a shader to the widgets painted.
  final TablePlaceholderBuilder placeholderBuilder;

  /// A callback that allows application of a shader to the placeholder rows.
  final TablePlaceholderShade? placeholderShade;

  /// A function that will be called on-demand enabling wrapping vertically
  /// scrollable table body section that contains all visible rows including
  /// placeholders.
  ///
  /// This would usually wrap the body in [Material] widget.
  final TableBodyContainerBuilder bodyContainerBuilder;

  /// A function that will be called on-demand for each cell in a header
  /// in order to build a widget for that section of a header.
  ///
  /// If null, no header will be built.
  final TableHeaderBuilder? headerBuilder;

  /// Height of a header. If null, [rowHeight] will be used instead.
  final double headerHeight;

  /// A function that will be called on-demand for each cell in a footer
  /// in order to build a widget for that section of a footer.
  ///
  /// If null, no footer will be built.
  final TableFooterBuilder? footerBuilder;

  /// Height of a footer. If null, [rowHeight] will be used instead.
  final double footerHeight;

  /// Minimum scrollable width that may not be taken up by frozen columns.
  /// If a resulting scrollable width is less than this property, columns
  /// will be unfrozen according to freeze priority until scrollable width
  /// is greater than or equal to this property.
  ///
  /// If null, the [minScrollableWidthRatio] is used to calculate the minimum
  /// scrollable width, otherwise this property takes priority.
  final double? minScrollableWidth;

  /// Minimum scrollable width ratio in relation to the width of a table.
  /// Used to calculate [minScrollableWidth] depending on an overall table width
  /// if that property is null.
  final double minScrollableWidthRatio;

  /// Padding for the scrollable part of the table.
  /// Primarily used to leave space for the scrollbars.
  /// If null, predefined insets will be used based on a target platform.
  final EdgeInsets? scrollPadding;

  /// Determines whether to add a horizontal scrollbar
  /// Defaults to true
  final bool showHorizontalScrollBar;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late TableViewController _controller;
  final _stickyHorizontalOffset = ValueNotifier<double>(.0);

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TableViewController();
  }

  @override
  void didUpdateWidget(covariant TableView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller = widget.controller ?? _controller;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalScrollbarOffset = Offset(
      0,
      widget.footerBuilder == null ? 0 : widget.footerHeight,
    );

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: widget.columns.isEmpty
          ? const SizedBox()
          : LayoutBuilder(
              builder: (context, constraints) {
                final scrollable = Scrollable(
                    controller: _controller.horizontalScrollController,
                    clipBehavior: Clip.none,
                    axisDirection: AxisDirection.right,
                    viewportBuilder: _buildViewport);
                if (widget.showHorizontalScrollBar) {
                  return Transform.translate(
                    offset: -horizontalScrollbarOffset,
                    transformHitTests: false,
                    child: Scrollbar(
                      controller: _controller.horizontalScrollController,
                      interactive: true,
                      trackVisibility: true,
                      thumbVisibility: true,
                      child: Transform.translate(
                        offset: horizontalScrollbarOffset,
                        transformHitTests: false,
                        child: scrollable,
                      ),
                    ),
                  );
                }
                return scrollable;
              },
            ),
    );
  }

  Widget _buildViewport(BuildContext context, ViewportOffset horizontalOffset) {
    final scrollPadding =
        widget.scrollPadding ?? determineScrollPadding(context);

    final dividerThickness = Theme.of(context).dividerTheme.thickness ?? 2.0;
    final dividerColor =
        Theme.of(context).dividerTheme.color ?? Theme.of(context).dividerColor;

    return ScrollDimensionsApplicator(
      position: _controller.horizontalScrollController.position,
      axis: Axis.horizontal,
      scrollExtent: widget.columns.fold<double>(
              .0, (previousValue, element) => previousValue + element.width) +
          scrollPadding.horizontal,
      child: LayoutBuilder(
        builder: (context, constraints) => TableContentLayout(
          scrollPadding: scrollPadding,
          width: constraints.maxWidth,
          minScrollableWidthRatio: widget.minScrollableWidthRatio,
          columns: widget.columns,
          horizontalOffset: horizontalOffset,
          stickyHorizontalOffset: _stickyHorizontalOffset,
          minScrollableWidth: widget.minScrollableWidth,
          child: Builder(
            builder: (context) {
              final body = widget.bodyContainerBuilder(
                context,
                ClipRect(
                  child: NotificationListener<OverscrollNotification>(
                    // Suppress OverscrollNotification events that escape from the inner scrollable
                    onNotification: (notification) => true,
                    child: Scrollbar(
                      controller: _controller.verticalScrollController,
                      interactive: true,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: Scrollable(
                        controller: _controller.verticalScrollController,
                        clipBehavior: Clip.none,
                        axisDirection: AxisDirection.down,
                        viewportBuilder: (context, verticalOffset) =>
                            TableSection(
                          verticalOffset: verticalOffset,
                          rowHeight: widget.rowHeight,
                          placeholderShade: widget.placeholderShade,
                          child: TableViewport(
                            clipBehavior: Clip.none,
                            offset: verticalOffset,
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.only(
                                  top: scrollPadding.top,
                                  bottom: scrollPadding.bottom,
                                ),
                                sliver: SliverTableViewBody(
                                  rowCount: widget.rowCount,
                                  rowHeight: widget.rowHeight,
                                  rowBuilder: widget.rowBuilder,
                                  placeholderBuilder: widget.placeholderBuilder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              final headerBuilder = widget.headerBuilder;
              final footerBuilder = widget.footerBuilder;
              if (headerBuilder == null && footerBuilder == null) {
                return SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: body,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (headerBuilder != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: widget.headerHeight,
                      child: TableSection(
                        verticalOffset: null,
                        rowHeight: widget.headerHeight,
                        placeholderShade: null,
                        child: headerBuilder(context, contentBuilder),
                      ),
                    ),
                    Divider(
                      color: dividerColor,
                      height: dividerThickness,
                      thickness: dividerThickness,
                    ),
                  ],
                  Expanded(child: body),
                  if (footerBuilder != null) ...[
                    Divider(
                      color: dividerColor,
                      height: dividerThickness,
                      thickness: dividerThickness,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: widget.footerHeight,
                      child: TableSection(
                        verticalOffset: null,
                        rowHeight: widget.footerHeight,
                        placeholderShade: null,
                        child: footerBuilder(context, contentBuilder),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _defaultBodyContainerBuilder(
        BuildContext context, Widget bodyContainer) =>
    bodyContainer;

Widget _defaultPlaceholderBuilder(
  BuildContext context,
  TableRowContentBuilder contentBuilder,
) =>
    contentBuilder(
      context,
      (context, column) {
        final theme = Theme.of(context);

        // get rid of transparency for the sake of a shader
        final color = Color.alphaBlend(
          theme.dividerColor,
          theme.colorScheme.background,
        );

        return Padding(
          padding: EdgeInsets.all(8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        );
      },
    );
