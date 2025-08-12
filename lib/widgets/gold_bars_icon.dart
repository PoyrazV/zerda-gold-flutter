import 'package:flutter/material.dart';

class GoldBarsIcon extends StatelessWidget {
  final double size;
  final Color color;
  
  const GoldBarsIcon({
    Key? key,
    this.size = 24,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: GoldBarsPainter(color: color),
    );
  }
}

class GoldBarsPainter extends CustomPainter {
  final Color color;
  
  GoldBarsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Calculate bar dimensions
    final barWidth = size.width * 0.25;
    final barHeight = size.height * 0.15;
    final spacing = size.width * 0.02;
    
    // Bottom row - 3 bars
    final bottomY = size.height * 0.7;
    for (int i = 0; i < 3; i++) {
      final x = size.width * 0.125 + (i * (barWidth + spacing));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottomY, barWidth, barHeight),
        Radius.circular(1),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, strokePaint);
    }
    
    // Middle row - 2 bars
    final middleY = size.height * 0.5;
    for (int i = 0; i < 2; i++) {
      final x = size.width * 0.25 + (i * (barWidth + spacing));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, middleY, barWidth, barHeight),
        Radius.circular(1),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, strokePaint);
    }
    
    // Top row - 1 bar
    final topY = size.height * 0.3;
    final topX = size.width * 0.375;
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(topX, topY, barWidth, barHeight),
      Radius.circular(1),
    );
    canvas.drawRRect(topRect, paint);
    canvas.drawRRect(topRect, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}