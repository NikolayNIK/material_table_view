import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/sliver_table_body.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_column_scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/table_content_layout.dart';
import 'package:material_table_view/src/table_layout_box.dart';
import 'package:material_table_view/src/table_placeholder_shade.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_row_reorder.dart';
import 'package:material_table_view/src/table_scaffold.dart';
import 'package:material_table_view/src/table_scroll_configuration.dart';
import 'package:material_table_view/src/table_scrollbar.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_section_offset.dart';
import 'package:material_table_view/src/table_section_overlay.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_view_style.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';
import 'package:material_table_view/src/table_viewport.dart';

/// Material-style widget that displays its content in a both vertically and
/// horizontally scrollable table with fixed-width freezable columns.
///
/// This widget will try to expand to the highest constraints given, unless
/// `shrinkWrapVertical` is used. Make sure to either put it inside a box with
/// a finite size or to set `shrinkWrapVertical` to true to let this widget
/// calculate its height (width is still required to be finite).
class TableView extends StatefulWidget {
  const TableView.builder({
    super.key,
    this.style,
    this.controller,
    required this.columns,
    this.textDirection,
    this.minScrollableWidth,
    this.minScrollableWidthRatio,
    this.rowReorder,
    this.addAutomaticKeepAlives = false,
    required this.rowCount,
    required this.rowHeight,
    this.rowHeightBuilder,
    this.rowPrototype,
    required this.rowBuilder,
    this.placeholderBuilder = _defaultPlaceholderBuilder,
    this.placeholderRowBuilder,
    this.placeholderShade,
    this.bodyContainerBuilder = _defaultBodyContainerBuilder,
    this.headerBuilder,
    double? headerHeight,
    this.footerBuilder,
    double? footerHeight,
    this.physics,
    this.shrinkWrapVertical = false,
    this.shrinkWrapHorizontal = false,
  })  : assert(rowCount >= 0),
        assert(rowHeight == null || rowHeight > 0),
        assert(headerHeight == null || headerHeight > 0),
        assert(footerHeight == null || footerHeight > 0),
        assert(
            headerBuilder == null || headerHeight != null || rowHeight != null,
            'When the header is used, either headerHeight or rowHeight should be specified'),
        assert(
            footerBuilder == null || footerHeight != null || rowHeight != null,
            'When the footer is used, either footerHeight or rowHeight should be specified'),
        assert(minScrollableWidth == null || minScrollableWidth > 0),
        assert(minScrollableWidthRatio == null ||
            (minScrollableWidthRatio >= 0 && minScrollableWidthRatio <= 1)),
        headerHeight = headerHeight ?? rowHeight ?? 0,
        footerHeight = footerHeight ?? rowHeight ?? 0;

  /// Display style of the table.
  final TableViewStyle? style;

  /// Controller for the state of a table.
  final TableViewController? controller;

  /// List of column descriptions to display in a table.
  final List<TableColumn> columns;

  /// Text direction of the table. Determines horizontal scroll axis and column
  /// layout direction as well.
  ///
  /// If null, the value from the closest instance
  /// of the [Directionality] class that encloses the table will be used.
  final TextDirection? textDirection;

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
  final double? minScrollableWidthRatio;

  /// When a non-null value is specified, [SliverReorderableList] instantiated
  /// using properties from this object will be used by the table.
  /// This enables row reordering using the same way as one would
  /// working with [ReorderableListView]. This also means that each row widget
  /// built by a [rowBuilder] is required to have a unique key.
  ///
  /// Changing this property from null to non-null value (and vice versa)
  /// for currently live widget will lead to state loss of all the rows and
  /// cells.
  final TableRowReorder? rowReorder;

  /// Whether to wrap each row in an [AutomaticKeepAlive].
  ///
  /// It is generally considered a bad practice to make the rows of a table
  /// stateful as doing so may significantly impact scrolling performance.
  /// Whenever scrolling is used more than updating,
  /// consider rebuilding the entire [TableView] or [SliverTableView] widget
  /// instead whenever its content gets changed. The widgets are designed to
  /// be rebuilt in a reasonable processing time.
  ///
  /// Defaults to `false`.
  final bool addAutomaticKeepAlives;

  /// Count of rows displayed in a table.
  final int rowCount;

  /// Height of each row displayed in a table.
  ///
  /// When set to [null], the height of each row is computed during layout,
  /// similar to the [Row] widget, meaning each row can have different height.
  /// Additionally, wrapping the table row widget in the [IntrinsicHeight]
  /// will make all cells as tall as the tallest visible cell.
  ///
  /// Prefer setting this value to not-null to increase performance.
  /// When it is not possible, consider specifying [rowHeightBuilder] or
  /// [rowPrototype] to improve the performance instead.
  final double? rowHeight;

  /// When this function is set and the [rowHeight] is set to `null`,
  /// this function will be used to determine the height of each row,
  /// which will improve performance.
  final ItemExtentBuilder? rowHeightBuilder;

  /// When this property is set, the [rowHeight] is set to `null`
  /// and the [rowHeightBuilder] is set to `null` this widget will be used
  /// to determine the height of each row of the table, which will improve
  /// the performance.
  final Widget? rowPrototype;

  /// A function that will be called on-demand for each row displayed
  /// in order to build a widget of a row of the table.
  ///
  /// In case of this function returning null, the corresponding row will be
  /// replaced with a placeholder. This enables additional behaviour described in a
  /// [placeholderBuilder] property.
  final TableRowBuilder rowBuilder;

  /// A function that will be called on-demand for building the placeholder
  /// row widget. As oppose to [placeholderRowBuilder],
  /// it never gets called more than once per build cycle as the
  /// same widget is reused for every placeholder row built.
  ///
  /// [placeholderShade] can be used to apply a shader to the widgets painted.
  final TablePlaceholderBuilder placeholderBuilder;

  /// A function that will be called on-demand for building a placeholder
  /// row widget. As oppose to [placeholderBuilder], this function gets called
  /// to build every placeholder row individually. Consider using
  /// [placeholderBuilder] when all placeholder rows are the same as each other.
  ///
  /// When this function is `null` or it returns `null` the result of
  /// [placeholderBuilder] function call will be used instead.
  ///
  /// [placeholderShade] can be used to apply a shader to the widgets painted.
  final TablePlaceholderRowBuilder? placeholderRowBuilder;

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
  ///
  /// If [headerBuilder] is specified and [rowHeight] is `null`,
  /// [headerHeight] becomes required.
  final double headerHeight;

  /// A function that will be called on-demand for each cell in a footer
  /// in order to build a widget for that section of a footer.
  ///
  /// If null, no footer will be built.
  final TableFooterBuilder? footerBuilder;

  /// Height of a footer. If null, [rowHeight] will be used instead.
  /// If [footerBuilder] is specified and [rowHeight] is `null`,
  /// [footerHeight] becomes required.
  final double footerHeight;

  /// How the vertical scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions. Furthermore, if [primary] is
  /// false, then the user cannot scroll if there is insufficient content to
  /// scroll, while if [primary] is true, they can always attempt to scroll.
  ///
  /// To force the scroll view to always be scrollable even if there is
  /// insufficient content, as if [primary] was true but without necessarily
  /// setting it to true, provide an [AlwaysScrollableScrollPhysics] physics
  /// object, as in:
  ///
  /// ```dart
  ///   physics: const AlwaysScrollableScrollPhysics(),
  /// ```
  ///
  /// To force the scroll view to use the default platform conventions and not
  /// be scrollable if there is insufficient content, regardless of the value of
  /// [primary], provide an explicit [ScrollPhysics] object, as in:
  ///
  /// ```dart
  ///   physics: const ScrollPhysics(),
  /// ```
  ///
  /// The physics can be changed dynamically (by providing a new object in a
  /// subsequent build), but new physics will only take effect if the _class_ of
  /// the provided object changes. Merely constructing a new instance with a
  /// different configuration is insufficient to cause the physics to be
  /// reapplied. (This is because the final object used is generated
  /// dynamically, which can be relatively expensive, and it would be
  /// inefficient to speculatively create this object each frame to see if the
  /// physics should be updated.)
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [physics].
  final ScrollPhysics? physics;

  /// Whether the height of the [TableView] in should be determined by
  /// the contents being viewed.
  ///
  /// If the [TableView] does not shrink wrap, then the [TableView] will expand
  /// to the maximum allowed height. If the [TableView] has unbounded height,
  /// then [shrinkWrapVertical] must be true.
  ///
  /// Shrink wrapping the content of the [TableView] is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// [TableView] needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrapVertical;

  /// Whether the width of the [TableView] in should be determined by
  /// the contents being viewed.
  ///
  /// If the [TableView] does not shrink wrap, then the [TableView] will expand
  /// to the maximum allowed width. If the [TableView] has unbounded width,
  /// then [shrinkWrapHorizontal] must be true.
  ///
  /// Defaults to false.
  final bool shrinkWrapHorizontal;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView>
    implements TableColumnControlsControllable<TableView> {
  late TableViewController _controller;
  final _stickyHorizontalOffset = ValueNotifier<double>(.0);

  @override
  late TextDirection textDirection;

  List<TableColumn>? _columns;

  @override
  List<TableColumn> get columns => _columns ?? widget.columns;

  @override
  ScrollController get horizontalScrollController =>
      _controller.horizontalScrollController;

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
    final style = ResolvedTableViewStyle.of(
      context,
      style: widget.style,
      sliver: false,
    );

    final horizontalScrollbarOffset = Offset(
      0,
      widget.footerBuilder == null ? 0 : widget.footerHeight,
    );

    textDirection = widget.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: TableScrollConfiguration(
        child: Transform.translate(
          offset: -horizontalScrollbarOffset,
          transformHitTests: false,
          child: TableScrollbar(
            controller: _controller.horizontalScrollController,
            style: style.scrollbars.horizontal,
            child: Transform.translate(
              offset: horizontalScrollbarOffset,
              transformHitTests: false,
              child: Scrollable(
                controller: _controller.horizontalScrollController,
                clipBehavior: Clip.none,
                axisDirection: textDirectionToAxisDirection(textDirection),
                viewportBuilder: (context, position) =>
                    _buildLayout(context, style, position),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    ResolvedTableViewStyle style,
    ViewportOffset horizontalOffset,
  ) {
    final scrollPadding = style.scrollPadding;

    return TableLayoutBox(
      columns: widget.columns,
      scrollPadding: scrollPadding,
      shrinkWrapHorizontal: widget.shrinkWrapHorizontal,
      builder: (context, columns, width) {
        return TableColumnScrollDimensionsApplicator(
          position: _controller.horizontalScrollController.position,
          columns: columns,
          scrollPadding: scrollPadding,
          child: TableContentLayout(
            verticalDividersStyle: style.dividers.vertical,
            scrollPadding: scrollPadding,
            textDirection: textDirection,
            width: width,
            fixedRowHeight: widget.rowHeight != null,
            minScrollableWidthRatio:
                widget.minScrollableWidthRatio ?? style.minScrollableWidthRatio,
            columns: columns,
            horizontalOffset: horizontalOffset,
            stickyHorizontalOffset: _stickyHorizontalOffset,
            minScrollableWidth: widget.minScrollableWidth,
            child: Builder(
              builder: (context) => TableScaffold(
                shrinkWrapVertical: widget.shrinkWrapVertical,
                dividersStyle: style.dividers.horizontal,
                header: widget.headerBuilder == null
                    ? null
                    : ClipRect(
                        child: TableSection(
                          rowHeight: widget.headerHeight,
                          placeholderShade: null,
                          child: widget.headerBuilder!(
                              context, headerFooterContentBuilder),
                        ),
                      ),
                headerHeight: widget.headerHeight,
                body: NotificationListener<OverscrollNotification>(
                  onNotification: (notification) {
                    // Prevent horizontal scrollable from receiving
                    // overscroll notification because it starts to freak out.
                    // Dispatch it out from the TableView instead
                    // so something like RefreshIndicator can act upon it.
                    notification.dispatch(this.context);
                    return true;
                  },
                  child: widget.bodyContainerBuilder(
                    context,
                    ClipRect(
                      child: TableScrollbar(
                        controller: _controller.verticalScrollController,
                        style: style.scrollbars.vertical,
                        child: Scrollable(
                          controller: _controller.verticalScrollController,
                          clipBehavior: Clip.none,
                          axisDirection: AxisDirection.down,
                          physics: widget.physics,
                          viewportBuilder: (context, position) =>
                              _buildVerticalViewport(scrollPadding, position),
                        ),
                      ),
                    ),
                  ),
                ),
                footer: widget.footerBuilder == null
                    ? null
                    : ClipRect(
                        child: TableSection(
                          rowHeight: widget.footerHeight,
                          placeholderShade: null,
                          child: widget.footerBuilder!(
                              context, headerFooterContentBuilder),
                        ),
                      ),
                footerHeight: widget.footerHeight,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalViewport(
    EdgeInsets scrollPadding,
    ViewportOffset verticalOffset,
  ) {
    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.only(
          top: scrollPadding.top,
          bottom: scrollPadding.bottom,
        ),
        sliver: SliverTableBody(
          rowCount: widget.rowCount,
          rowHeight: widget.rowHeight,
          rowHeightBuilder: widget.rowHeightBuilder,
          rowPrototype: widget.rowPrototype,
          rowBuilder: widget.rowBuilder,
          placeholderBuilder: widget.placeholderBuilder,
          placeholderRowBuilder: widget.placeholderRowBuilder,
          useHigherScrollable: false,
          addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
          rowReorder: widget.rowReorder,
        ),
      ),
    ];

    Widget result = widget.shrinkWrapVertical
        ? TableShrinkWrappingViewport(
            clipBehavior: Clip.none,
            offset: verticalOffset,
            slivers: slivers,
          )
        : TableViewport(
            clipBehavior: Clip.none,
            offset: verticalOffset,
            slivers: slivers,
          );

    if (widget.rowReorder != null) {
      result = TableSectionOverlay(child: result);
    }

    return TableSection(
      verticalOffset: TableSectionOffset.wrapViewportOffset(verticalOffset),
      rowHeight: widget.rowHeight,
      placeholderShade: widget.placeholderShade,
      child: result,
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
          theme.colorScheme.surface,
        );

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
          ),
        );
      },
    );
