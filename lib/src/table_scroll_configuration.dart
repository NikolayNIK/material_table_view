import 'package:flutter/widgets.dart';

class TableScrollConfiguration extends StatelessWidget {
  final Widget child;

  const TableScrollConfiguration({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: child,
    );
  }
}
