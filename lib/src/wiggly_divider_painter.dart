import 'package:flutter/rendering.dart';

class WigglyDividerPainter extends CustomPainter {
  final Color leftLineColor, rightLineColor;
  final double leftLineX, rightLineX;
  final double lineWidth;
  final double patternHeight;
  final double verticalOffset;
  final double horizontalLeftOffset, horizontalRightOffset;

  WigglyDividerPainter({
    required this.leftLineColor,
    required this.rightLineColor,
    required this.leftLineX,
    required this.rightLineX,
    required this.lineWidth,
    required this.patternHeight,
    required this.verticalOffset,
    required this.horizontalLeftOffset,
    required this.horizontalRightOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leftLineColor.alpha == 0 && rightLineColor.alpha == 0) return;

    Path wigglyPath(double horizontalOffset) {
      final path = Path();

      final halfPatternHeight = patternHeight / 2;
      double verticalOffset = -(this.verticalOffset % patternHeight);
      path.moveTo(0, verticalOffset);

      final end = size.height + halfPatternHeight;
      while (verticalOffset < end) {
        path
          ..lineTo(horizontalOffset, verticalOffset += halfPatternHeight)
          ..lineTo(0, verticalOffset += halfPatternHeight);
      }

      return path;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    if (leftLineColor.alpha != 0) {
      paint.color = leftLineColor;
      canvas
        ..save()
        ..translate(leftLineX, 0)
        ..drawPath(wigglyPath(horizontalLeftOffset), paint)
        ..restore();
    }

    if (rightLineColor.alpha != 0) {
      paint.color = rightLineColor;
      canvas
        ..save()
        ..translate(size.width - rightLineX, 0)
        ..drawPath(wigglyPath(-horizontalRightOffset), paint)
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
      horizontalLeftOffset != oldDelegate.horizontalLeftOffset ||
      horizontalRightOffset != oldDelegate.horizontalRightOffset;
}
