import 'package:flutter/rendering.dart';

class WigglyRowClipper extends CustomClipper<Path> {
  final double wiggleInnerOffset, wiggleOuterOffset;
  Path? _path;

  WigglyRowClipper({
    required this.wiggleInnerOffset,
    required this.wiggleOuterOffset,
  });

  @override
  Path getClip(Size size) => _path ??= Path()
    ..moveTo(size.width - wiggleInnerOffset, 0)
    ..lineTo(size.width + wiggleOuterOffset, size.height / 2)
    ..lineTo(size.width - wiggleInnerOffset, size.height)
    ..lineTo(wiggleInnerOffset, size.height)
    ..lineTo(-wiggleOuterOffset, size.height / 2)
    ..lineTo(wiggleInnerOffset, 0);

  @override
  bool shouldReclip(covariant WigglyRowClipper oldClipper) =>
      oldClipper.wiggleInnerOffset != wiggleInnerOffset ||
      oldClipper.wiggleOuterOffset != wiggleOuterOffset;
}
