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
  late final List<OverlayEntry> _initialEntries = [
    OverlayEntry(
      canSizeOverlay: true,
      builder: (context) => widget.child,
    )
  ];

  @override
  Widget build(BuildContext context) => Overlay(
        clipBehavior: Clip.none,
        initialEntries: _initialEntries,
      );
}
