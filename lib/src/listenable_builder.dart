import 'package:flutter/widgets.dart';

/// TODO remove once this widget is available in the Flutter SDK
class XListenableBuilder extends StatefulWidget {
  const XListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  final Listenable listenable;

  final TransitionBuilder builder;

  final Widget? child;

  @override
  State<StatefulWidget> createState() => _XListenableBuilderState();
}

class _XListenableBuilderState<T> extends State<XListenableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(XListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_valueChanged);
      widget.listenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}
