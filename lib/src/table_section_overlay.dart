import 'package:flutter/widgets.dart';

class TableSectionOverlay extends StatefulWidget {
  final Widget child;

  const TableSectionOverlay({
    super.key,
    required this.child,
  });

  @override
  State<TableSectionOverlay> createState() => _TableSectionOverlayState();
}

class _TableSectionOverlayState extends State<TableSectionOverlay> {
  late OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();

    // TODO get semantics working somehow

    _overlayEntry = OverlayEntry(
      builder: (context) => Semantics(
        excludeSemantics: true,
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Overlay(
        clipBehavior: Clip.none,
        initialEntries: [_overlayEntry],
      );
}
