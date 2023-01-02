import 'package:flutter/rendering.dart';

class WigglyRowClipper extends CustomClipper<Path> {
  final double wiggleLeftOffset, wiggleRightOffset;
  Path? _path;

  WigglyRowClipper({
    required this.wiggleLeftOffset,
    required this.wiggleRightOffset,
  });

  @override
  Path getClip(Size size) => _path ??= Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width - wiggleRightOffset, size.height / 2)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..lineTo(wiggleLeftOffset, size.height / 2)
    ..lineTo(0, 0);

  @override
  bool shouldReclip(covariant WigglyRowClipper oldClipper) =>
      oldClipper.wiggleLeftOffset != wiggleLeftOffset ||
      oldClipper.wiggleRightOffset != wiggleRightOffset;
}
