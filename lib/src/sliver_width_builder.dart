import 'package:flutter/widgets.dart';

class SliverCrossAxisExtentBuilder extends StatefulWidget {
  const SliverCrossAxisExtentBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    double crossAxisExtent,
  ) builder;

  @override
  State<SliverCrossAxisExtentBuilder> createState() =>
      _SliverCrossAxisExtentBuilderState();
}

class _SliverCrossAxisExtentBuilderState
    extends State<SliverCrossAxisExtentBuilder> {
  double? crossAxisExtent;
  Widget? child;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          final child = this.child;
          return crossAxisExtent == null ||
                  child == null ||
                  crossAxisExtent != constraints.crossAxisExtent
              ? this.child = widget.builder(
                  context,
                  constraints.crossAxisExtent,
                )
              : child;
        },
      );
}
