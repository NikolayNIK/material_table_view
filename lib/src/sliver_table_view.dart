import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_table_view/src/optional_wrap.dart';
import 'package:material_table_view/src/sliver_passthrough.dart';
import 'package:material_table_view/src/sliver_table_body.dart';
import 'package:material_table_view/src/sliver_width_builder.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_column_resolve_layout_extension.dart';
import 'package:material_table_view/src/table_column_scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/table_content_layout.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_scaffold.dart';
import 'package:material_table_view/src/table_scrollbar.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_section_offset.dart';
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
    required super.rowHeight,
    super.rowHeightBuilder,
    super.rowPrototype,
    required super.rowBuilder,
    super.placeholderBuilder,
    super.placeholderRowBuilder,
    super.placeholderShade,
    super.bodyContainerBuilder,
    super.headerBuilder,
    super.headerHeight,
    super.footerBuilder,
    super.footerHeight,
  }) : super.builder(physics: null);

  /// A scroll controller used for the horizontal scrolling of the table.
  final ScrollController? horizontalScrollController;

  @override
  State<SliverTableView> createState() => _SliverTableViewState();
}

class _SliverTableViewState extends State<SliverTableView>
    implements TableColumnControlsControllable<SliverTableView> {
  late ScrollController _horizontalScrollController;
  late ValueNotifier<double> _horizontalStickyOffset;

  List<TableColumn>? _columns;

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

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: SliverCrossAxisExtentBuilder(builder: (context, width) {
        final columns =
            widget.columns.resolveLayout(width - scrollPadding.horizontal);

        return SliverPassthrough(
          minHeight: headerHeight +
              max(scrollPadding.vertical, style.dividers.horizontal.space) +
              footerHeight,
          builder: (context, verticalOffset) => Transform.translate(
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
                      TableColumnScrollDimensionsApplicator(
                    position: _horizontalScrollController.position,
                    columns: columns,
                    scrollPadding: scrollPadding,
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
                      child: TableScaffold(
                        dividersStyle: style.dividers.horizontal,
                        header: widget.headerBuilder == null
                            ? null
                            : TableSection(
                                rowHeight: widget.headerHeight,
                                placeholderShade: null,
                                child: widget.headerBuilder!(
                                    context, headerFooterContentBuilder),
                              ),
                        headerHeight: headerHeight,
                        body: widget.bodyContainerBuilder(
                          context,
                          ClipRect(
                            child: TableSection(
                              rowHeight: widget.rowHeight,
                              verticalOffset:
                                  TableSectionOffset.wrapValueNotifier(
                                      verticalOffset),
                              placeholderShade: widget.placeholderShade,
                              child: OptionalWrap(
                                builder: widget.rowReorder == null
                                    ? null
                                    : (context, child) =>
                                        TableSectionOverlay(child: child),
                                child: BoxToSliverPassthrough(
                                  sliver: SliverPadding(
                                    padding: EdgeInsets.only(
                                      top: scrollPadding.top,
                                    ),
                                    sliver: SliverTableBody(
                                      rowCount: widget.rowCount,
                                      rowHeight: widget.rowHeight,
                                      rowHeightBuilder: widget.rowHeightBuilder,
                                      rowPrototype: widget.rowPrototype,
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
                        footer: widget.footerBuilder == null
                            ? null
                            : TableSection(
                                rowHeight: widget.footerHeight,
                                placeholderShade: null,
                                child: widget.footerBuilder!(
                                    context, headerFooterContentBuilder),
                              ),
                        footerHeight: footerHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
