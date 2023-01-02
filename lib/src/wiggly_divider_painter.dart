import 'package:flutter/rendering.dart';

class WigglyDividerPainter extends CustomPainter {
  final Color leftLineColor, rightLineColor;
  final double leftLineX, rightLineX;
  final double lineWidth;
  final double patternHeight;
  final double verticalOffset;
  final double horizontalInnerOffset, horizontalOuterOffset;

  WigglyDividerPainter({
    required this.leftLineColor,
    required this.rightLineColor,
    required this.leftLineX,
    required this.rightLineX,
    required this.lineWidth,
    required this.patternHeight,
    required this.verticalOffset,
    required this.horizontalInnerOffset,
    required this.horizontalOuterOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leftLineColor.alpha == 0 && rightLineColor.alpha == 0) return;

    final path = Path();
    {
      final halfPatternHeight = patternHeight / 2;
      double verticalOffset = -(this.verticalOffset % patternHeight);
      path.moveTo(horizontalInnerOffset, verticalOffset);

      final end = size.height + halfPatternHeight;
      while (verticalOffset < end) {
        path
          ..lineTo(-horizontalOuterOffset, verticalOffset += halfPatternHeight)
          ..lineTo(horizontalInnerOffset, verticalOffset += halfPatternHeight);
      }

      path.relativeLineTo(0, size.height + lineWidth);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    if (leftLineColor.alpha != 0) {
      paint.color = leftLineColor;
      canvas
        ..save()
        ..translate(leftLineX, 0)
        ..drawPath(path, paint)
        ..restore();
    }

    if (rightLineColor.alpha != 0) {
      paint.color = rightLineColor;
      canvas
        ..save()
        ..scale(-1.0, 1.0)
        ..translate(rightLineX - size.width, 0)
        // ..translate(size.width, 0)
        ..drawPath(path, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant WigglyDividerPainter oldDelegate) =>
      verticalOffset != oldDelegate.verticalOffset ||
      leftLineColor != oldDelegate.leftLineColor ||
      rightLineColor != oldDelegate.rightLineColor ||
      leftLineX != oldDelegate.leftLineX ||
      rightLineX != oldDelegate.rightLineX ||
      lineWidth != oldDelegate.lineWidth ||
      patternHeight != oldDelegate.patternHeight ||
      horizontalInnerOffset != oldDelegate.horizontalInnerOffset ||
      horizontalOuterOffset != oldDelegate.horizontalOuterOffset;
}
