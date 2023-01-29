import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

const _defaultItemHeight = 56.0;
const _defaultDividerRevealOffset = 32.0;

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
    @Deprecated('This property will be removed in the next major release. See CHANGELOG.md for more details.')
        this.placeholderBuilder,
    @Deprecated('This property will be removed in the next major release. See CHANGELOG.md for more details.')
        this.placeholderContainerBuilder,
    this.bodyContainerBuilder = _defaultBodyContainerBuilder,
    this.headerBuilder,
    this.headerHeight,
    this.footerBuilder,
    this.footerHeight,
    this.minScrollableWidth,
    this.minScrollableWidthRatio = .6180339887498547,
    this.dividerRevealOffset = _defaultDividerRevealOffset,
    this.scrollPadding,
  })  : assert(rowCount >= 0),
        assert(rowHeight > 0),
        assert(headerHeight == null || headerHeight > 0),
        assert(footerHeight == null || footerHeight > 0),
        assert(minScrollableWidth == null || minScrollableWidth > 0),
        assert(minScrollableWidthRatio >= 0 && minScrollableWidthRatio <= 1),
        assert(dividerRevealOffset > 0);

  @Deprecated('Use named constructor .builder instead')
  TableView({
    Key? key,
    TableViewController? controller,
    required List<TableColumn> columns,
    double? minScrollableWidth,
    double minScrollableWidthRatio = .6180339887498547,
    required int rowCount,
    double rowHeight = _defaultItemHeight,
    required _LegacyTableRowBuilder rowBuilder,
    _LegacyTableRowDecorator rowDecorator = _emptyRowDecorator,
    @Deprecated('This property will be removed in the next major release. See CHANGELOG.md for more details.')
        TableCellBuilder? placeholderBuilder,
    @Deprecated('This property will be removed in the next major release. See CHANGELOG.md for more details.')
        _LegacyTablePlaceholderDecorator
            placeholderDecorator = _emptyRowDecorator,
    @Deprecated('This property will be removed in the next major release. See CHANGELOG.md for more details.')
        TablePlaceholderContainerBuilder
            placeholderContainerBuilder = _emptyHeaderDecorator,
    TableBodyContainerBuilder bodyContainerBuilder =
        _defaultBodyContainerBuilder,
    TableCellBuilder? headerBuilder,
    double? headerHeight,
    _LegacyTableHeaderDecorator headerDecorator = _emptyHeaderDecorator,
    double? footerHeight,
    TableCellBuilder? footerBuilder,
    _LegacyTableFooterDecorator footerDecorator = _emptyFooterDecorator,
    double dividerRevealOffset = _defaultDividerRevealOffset,
    EdgeInsets? scrollPadding,
  }) : this.builder(
          key: key,
          controller: controller,
          columns: columns,
          minScrollableWidth: minScrollableWidth,
          minScrollableWidthRatio: minScrollableWidthRatio,
          rowCount: rowCount,
          rowHeight: rowHeight,
          rowBuilder: (context, row, contentBuilder) {
            final cellBuilder = rowBuilder(row);
            if (cellBuilder == null) {
              return null;
            }

            return rowDecorator(contentBuilder(context, cellBuilder), row);
          },
          placeholderBuilder: placeholderBuilder == null
              ? null
              : (context, row, contentBuilder) => placeholderDecorator(
                  contentBuilder(context, placeholderBuilder), row),
          placeholderContainerBuilder: placeholderContainerBuilder,
          bodyContainerBuilder: bodyContainerBuilder,
          headerBuilder: headerBuilder == null
              ? null
              : (context, contentBuilder) =>
                  headerDecorator(contentBuilder(context, headerBuilder)),
          headerHeight: headerHeight,
          footerBuilder: footerBuilder == null
              ? null
              : (context, contentBuilder) =>
                  footerDecorator(contentBuilder(context, footerBuilder)),
          footerHeight: footerHeight,
          dividerRevealOffset: dividerRevealOffset,
          scrollPadding: scrollPadding,
        );

  /// Count of fixed-height rows displayed in a table.
  final int rowCount;

  /// Height of each row displayed in a table.
  final double rowHeight;

  /// List of column descriptions to display in a table.
  final List<TableColumn> columns;

  /// Controller for the state of a table.
  final TableViewController? controller;

  /// A function that will be called on-demand for each row displayed
  /// in order to obtain a [TableCellBuilder] that will build a widget for
  /// a specified cell in that row.
  ///
  /// In case of this function returning null, the corresponding row will be
  // ignore: deprecated_member_use_from_same_package
  /// replaced with a placeholder, meaning that the [placeholderBuilder] must
  /// not be null. This enables additional behaviour described in a
  // ignore: deprecated_member_use_from_same_package
  /// [placeholderContainerBuilder] property.
  final TableRowBuilder rowBuilder;

  /// A function that will be called on-demand for each cell in a placeholder
  /// row in order to obtains a widget for that cell.
  @Deprecated(
      'This property will be removed in the next major release. See CHANGELOG.md for more details.')
  final TablePlaceholderBuilder? placeholderBuilder;

  /// A function that will be called on-demand in order to enable custom
  /// placeholder behaviour by wrapping already built widget that contains
  /// all visible placeholder rows with required offsets passed as an argument.
  ///
  /// For example, this can be used to wrap placeholders in a shimmer widget
  /// of your choice.
  @Deprecated(
      'This property will be removed in the next major release. See CHANGELOG.md for more details.')
  final TablePlaceholderContainerBuilder? placeholderContainerBuilder;

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
  final double? headerHeight;

  /// A function that will be called on-demand for each cell in a footer
  /// in order to build a widget for that section of a footer.
  ///
  /// If null, no footer will be built.
  final TableFooterBuilder? footerBuilder;

  /// Height of a footer. If null, [rowHeight] will be used instead.
  final double? footerHeight;

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

  /// Horizontal offset required for the divider separating frozen and
  /// scrollable columns to fully appear.
  final double dividerRevealOffset;

  /// Padding for the scrollable part of the table.
  /// Primarily used to leave space for the scrollbars.
  /// If null, predefined insets will be used based on a target platform.
  final EdgeInsets? scrollPadding;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late TableViewController _controller;

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
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: TableViewport(
          controller: _controller,
          columns: widget.columns,
          minScrollableWidth: widget.minScrollableWidth,
          minScrollableWidthRatio: widget.minScrollableWidthRatio,
          rowCount: widget.rowCount,
          rowHeight: widget.rowHeight,
          rowBuilder: widget.rowBuilder,
          // ignore: deprecated_member_use_from_same_package
          placeholderBuilder: widget.placeholderBuilder,
          // ignore: deprecated_member_use_from_same_package
          placeholderContainerBuilder: widget.placeholderContainerBuilder,
          bodyContainerBuilder: widget.bodyContainerBuilder,
          headerBuilder: widget.headerBuilder,
          headerHeight: widget.headerHeight ?? widget.rowHeight,
          footerHeight: widget.footerHeight ?? widget.rowHeight,
          footerBuilder: widget.footerBuilder,
          dividerRevealOffset: widget.dividerRevealOffset,
          scrollPadding:
              widget.scrollPadding ?? _determineScrollPadding(context),
        ),
      );

  EdgeInsets _determineScrollPadding(BuildContext context) {
    // TODO determining paddings for the scrollbars based on a target platform seems stupid
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        return const EdgeInsets.only(right: 4.0, bottom: 4.0);
      case TargetPlatform.iOS:
        return const EdgeInsets.only(right: 6.0, bottom: 6.0);
      default:
        return const EdgeInsets.only(right: 14.0, bottom: 10.0);
    }
  }
}

Widget _defaultBodyContainerBuilder(
        BuildContext context, Widget bodyContainer) =>
    Material(child: bodyContainer);

Widget _emptyRowDecorator(Widget rowWidget, int _) => rowWidget;

Widget _emptyHeaderDecorator(Widget headerWidget) => headerWidget;

const _LegacyTableFooterDecorator _emptyFooterDecorator = _emptyHeaderDecorator;

/// Function used to retrieve a [TableCellBuilder] for a specific row.
/// Returning null indicates the intent to replace that row with a placeholder.
typedef _LegacyTableRowBuilder = TableCellBuilder? Function(int row);

/// Function used to wrap a given row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef _LegacyTableRowDecorator = Widget Function(
    Widget rowWidget, int rowIndex);

/// Function used to wrap a given placeholder row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef _LegacyTablePlaceholderDecorator = Widget Function(
  Widget placeholderWidget,
  int rowIndex,
);

/// Function used to wrap a given header row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef _LegacyTableHeaderDecorator = Widget Function(Widget headerWidget);

/// Function used to wrap a given footer row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef _LegacyTableFooterDecorator = Widget Function(Widget footerWidget);
