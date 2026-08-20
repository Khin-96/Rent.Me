import 'package:flutter/material.dart';

class AuthArtIllustration extends StatelessWidget {
  final bool isLogin;

  const AuthArtIllustration({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 140,
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(200, 140),
          painter: _AuthArtPainter(isLogin: isLogin),
        ),
      ),
    );
  }
}

class _AuthArtPainter extends CustomPainter {
  final bool isLogin;

  _AuthArtPainter({required this.isLogin});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bgPaint = Paint()
      ..color = const Color(0xFFF2F2F0)
      ..style = PaintingStyle.fill;

    // Background soft grey circular halo
    canvas.drawCircle(center, 65, bgPaint);

    final blackFill = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final blackStroke = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinStroke = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isLogin) {
      // --- House Illustration ---
      final houseLeft = center.dx - 36;
      final houseTop = center.dy - 10;
      const houseWidth = 56.0;
      const houseHeight = 42.0;

      // Roof
      final roofPath = Path()
        ..moveTo(houseLeft - 10, houseTop)
        ..lineTo(houseLeft + houseWidth / 2, houseTop - 28)
        ..lineTo(houseLeft + houseWidth + 10, houseTop);
      canvas.drawPath(roofPath, blackStroke);

      // House Body
      final houseRect = Rect.fromLTWH(houseLeft, houseTop, houseWidth, houseHeight);
      canvas.drawRect(houseRect, whiteFill);
      canvas.drawRect(houseRect, blackStroke);

      // Door
      final doorRect = Rect.fromLTWH(houseLeft + 18, houseTop + 16, 20, 26);
      canvas.drawRect(doorRect, blackFill);

      // Windows
      canvas.drawRect(Rect.fromLTWH(houseLeft + 6, houseTop + 8, 10, 10), thinStroke);
      canvas.drawRect(Rect.fromLTWH(houseLeft + 40, houseTop + 8, 10, 10), thinStroke);

      // --- Key ---
      canvas.save();
      canvas.translate(center.dx + 38, center.dy + 15);
      canvas.rotate(-0.4);
      canvas.drawCircle(const Offset(0, 0), 9, blackStroke);
      canvas.drawRect(const Rect.fromLTWH(8, -2, 24, 4), blackFill);
      canvas.drawRect(const Rect.fromLTWH(24, 2, 4, 6), blackFill);
      canvas.drawRect(const Rect.fromLTWH(30, 2, 4, 4), blackFill);
      canvas.restore();

      // --- Padlock Shield on Top ---
      final shieldLeft = center.dx - 12;
      final shieldTop = center.dy - 56;
      final shieldPath = Path()
        ..moveTo(shieldLeft, shieldTop + 4)
        ..lineTo(shieldLeft + 12, shieldTop)
        ..lineTo(shieldLeft + 24, shieldTop + 4)
        ..lineTo(shieldLeft + 24, shieldTop + 14)
        ..quadraticBezierTo(shieldLeft + 24, shieldTop + 24, shieldLeft + 12, shieldTop + 28)
        ..quadraticBezierTo(shieldLeft, shieldTop + 24, shieldLeft, shieldTop + 14)
        ..close();
      canvas.drawPath(shieldPath, blackFill);

      // Checkmark inside shield
      final checkPath = Path()
        ..moveTo(shieldLeft + 7, shieldTop + 14)
        ..lineTo(shieldLeft + 11, shieldTop + 18)
        ..lineTo(shieldLeft + 18, shieldTop + 9);
      canvas.drawPath(checkPath, whiteStroke);
    } else {
      // --- Register Illustration (Person & Verified Checklist) ---
      // Person Head
      canvas.drawCircle(Offset(center.dx - 30, center.dy - 18), 13, blackFill);

      // Person Body
      final bodyPath = Path()
        ..moveTo(center.dx - 52, center.dy + 38)
        ..quadraticBezierTo(center.dx - 52, center.dy + 8, center.dx - 30, center.dy + 8)
        ..quadraticBezierTo(center.dx - 8, center.dy + 8, center.dx - 8, center.dy + 38)
        ..close();
      canvas.drawPath(bodyPath, blackFill);

      // Clipboard
      final clipRect = Rect.fromLTWH(center.dx + 4, center.dy - 18, 44, 56);
      canvas.drawRRect(RRect.fromRectAndRadius(clipRect, const Radius.circular(4)), whiteFill);
      canvas.drawRRect(RRect.fromRectAndRadius(clipRect, const Radius.circular(4)), blackStroke);

      // Clipboard Clip Top
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx + 16, center.dy - 23, 20, 9),
          const Radius.circular(2),
        ),
        blackFill,
      );

      // Checklist Lines
      canvas.drawLine(
        Offset(center.dx + 12, center.dy - 2),
        Offset(center.dx + 38, center.dy - 2),
        thinStroke,
      );
      canvas.drawLine(
        Offset(center.dx + 12, center.dy + 8),
        Offset(center.dx + 38, center.dy + 8),
        thinStroke,
      );
      canvas.drawLine(
        Offset(center.dx + 12, center.dy + 18),
        Offset(center.dx + 30, center.dy + 18),
        thinStroke,
      );

      // Checkmark on clipboard
      final checkPath = Path()
        ..moveTo(center.dx + 12, center.dy + 26)
        ..lineTo(center.dx + 18, center.dy + 32)
        ..lineTo(center.dx + 32, center.dy + 16);
      canvas.drawPath(checkPath, blackStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthArtPainter oldDelegate) =>
      oldDelegate.isLogin != isLogin;
}
