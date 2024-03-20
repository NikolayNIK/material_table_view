import 'package:flutter/widgets.dart';

class OptionalWrap extends StatelessWidget {
  final Widget Function(BuildContext context, Widget child)? builder;
  final Widget child;

  const OptionalWrap({
    super.key,
    this.builder,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => builder?.call(context, child) ?? child;
}
