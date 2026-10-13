import 'package:flutter/material.dart';

/// The official four-color Google "G" mark, drawn vectorially (no asset) so
/// the authentication screens can show a proper "Continue with Google"
/// button. Paths match Google's 18x18 sign-in artwork.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 18;
    canvas.scale(scale);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = _blue;
    canvas.drawPath(
      Path()
        ..moveTo(17.64, 9.2045)
        ..cubicTo(17.64, 8.5664, 17.5827, 7.9527, 17.4764, 7.3636)
        ..lineTo(9.0, 7.3636)
        ..lineTo(9.0, 10.845)
        ..lineTo(13.8436, 10.845)
        ..cubicTo(13.635, 11.97, 13.0009, 12.9232, 12.0477, 13.5614)
        ..lineTo(12.0477, 15.8206)
        ..lineTo(14.9564, 15.8206)
        ..cubicTo(16.6978, 14.1301, 17.64, 11.8539, 17.64, 9.2045)
        ..close(),
      paint,
    );

    paint.color = _green;
    canvas.drawPath(
      Path()
        ..moveTo(9.0, 18.0)
        ..cubicTo(11.43, 18.0, 13.4673, 17.1939, 14.9564, 15.8195)
        ..lineTo(12.0477, 13.5604)
        ..cubicTo(11.2418, 14.1004, 10.2109, 14.42, 9.0, 14.42)
        ..cubicTo(6.6564, 14.42, 4.6714, 12.8369, 3.9631, 10.7091)
        ..lineTo(0.9574, 13.04)
        ..cubicTo(2.4382, 15.9834, 5.4818, 18.0, 9.0, 18.0)
        ..close(),
      paint,
    );

    paint.color = _yellow;
    canvas.drawPath(
      Path()
        ..moveTo(3.9631, 10.7091)
        ..cubicTo(3.7831, 10.1691, 3.6814, 9.5941, 3.6814, 9.0)
        ..cubicTo(3.6814, 8.4059, 3.7831, 7.8309, 3.9631, 7.2909)
        ..lineTo(3.9631, 4.959)
        ..lineTo(0.9574, 4.959)
        ..cubicTo(0.3509, 6.1705, 0.0, 7.5486, 0.0, 9.0)
        ..cubicTo(0.0, 10.4514, 0.3509, 11.8295, 0.9574, 13.041)
        ..lineTo(3.9631, 10.7091)
        ..close(),
      paint,
    );

    paint.color = _red;
    canvas.drawPath(
      Path()
        ..moveTo(9.0, 3.5805)
        ..cubicTo(10.3214, 3.5805, 11.5078, 4.0346, 12.4405, 4.9264)
        ..lineTo(15.0219, 2.345)
        ..cubicTo(13.4632, 0.8918, 11.4262, 0.0, 9.0, 0.0)
        ..cubicTo(5.4818, 0.0, 2.4382, 2.0166, 0.9574, 6.041)
        ..lineTo(3.9631, 8.3729)
        ..cubicTo(4.6714, 6.2451, 6.6564, 3.5805, 9.0, 3.5805)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}