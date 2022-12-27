import 'package:flutter/widgets.dart';

class ListenableBuilder extends StatefulWidget {
  const ListenableBuilder({
    super.key,
    required this.listenable,
    required this.builder,
  });

  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [ValueListenable] itself must not be null.
  final Listenable listenable;

  /// A [ValueWidgetBuilder] which builds a widget depending on the
  /// [valueListenable]'s value.
  ///
  /// Can incorporate a [valueListenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final WidgetBuilder builder;

  @override
  State<StatefulWidget> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState<T> extends State<ListenableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ListenableBuilder oldWidget) {
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
  Widget build(BuildContext context) => widget.builder(context);
}
