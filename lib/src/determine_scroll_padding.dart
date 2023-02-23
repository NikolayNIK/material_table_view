import 'package:flutter/material.dart';

EdgeInsets determineScrollPadding(BuildContext context) {
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
