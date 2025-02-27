import 'package:flutter/foundation.dart';
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

    _overlayEntry = OverlayEntry(
      canSizeOverlay: true,
      builder: (context) => widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget w = Overlay(
      clipBehavior: Clip.none,
      initialEntries: [_overlayEntry],
    );

    if (kDebugMode) {
      // This avoids assertion in _ScrollSemantics.assembleSemanticsNode
      // that checks that semantics children are tagged as
      // RenderViewport.useTwoPaneSemantics.
      // Semantics should work just fine at release builds.
      w = Semantics(
        excludeSemantics: true,
        child: w,
      );
    }

    return w;
  }
}
