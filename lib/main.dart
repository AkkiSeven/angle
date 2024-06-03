import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey[900], // Dark background
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Angle Inputter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _angle = 0.0;
  bool _dotPressed = false;

  bool _isPointInsideDot(Offset point, Offset dotCenter, double radius) {
    return (point - dotCenter).distance <= radius;
  }

  Rect _getDotTouchTarget(Offset dotCenter, double dotRadius) {
    const double touchTargetPadding = 24.0;
    return Rect.fromCenter(
      center: dotCenter,
      width: 2 * (dotRadius + touchTargetPadding),
      height: 2 * (dotRadius + touchTargetPadding),
    );
  }

  void _updateAngle(Offset position) {
    final Offset center = Offset(100, 100);
    final double radius = 100;

    double newAngle =
        atan2(position.dy - center.dy, position.dx - center.dx) * 180 / pi;
    if (newAngle < 0) newAngle += 360;

    // Snap to 1-degree increments
    newAngle = (newAngle / 1).round() * 1;

    setState(() {
      _angle = newAngle;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate display angle (0-180 degrees)
    double displayAngle = _angle <= 180 ? _angle : 360 - _angle; 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Angle: ${displayAngle.toStringAsFixed(1)}°', 
              style: const TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: GestureDetector(
                  onPanStart: (details) {
                    final dotRadius = _dotPressed ? 12.0 : 6.0;
                    final Offset center = Offset(100, 100);
                    final Offset dotCenter = Offset(
                      center.dx + 100 * cos(_angle * pi / 180),
                      center.dy + 100 * sin(_angle * pi / 180),
                    );

                    // Update the touch target area based on the current dot position
                    if (_getDotTouchTarget(dotCenter, dotRadius)
                        .contains(details.localPosition)) {
                      setState(() {
                        _dotPressed = true;
                        Vibration.vibrate();
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (_dotPressed) {
                      _updateAngle(details.localPosition);
                    }
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _dotPressed = false;
                    });
                  },
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: AnglePainter(_angle, _dotPressed),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnglePainter extends CustomPainter {
  final double angle;
  final bool dotPressed;

  AnglePainter(this.angle, this.dotPressed);

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw the circle
    final circlePaint = Paint()
      ..color = const Color(0xFF212121) // Dark gray
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, circlePaint);

    // Draw the reference line
    final referenceLinePaint = Paint()
      ..color = const Color(0xFF757575) // Light gray
      ..strokeWidth = 2.0;
    canvas.drawLine(
        center, Offset(center.dx + radius, center.dy), referenceLinePaint);

    // Calculate the end point of the rotating line based on the angle
    final double radian = angle * (pi / 180);
    final Offset endPoint = Offset(
      center.dx + radius * cos(radian),
      center.dy + radius * sin(radian),
    );

    // Draw the rotating line
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0;
    canvas.drawLine(center, endPoint, linePaint);

    // Draw the dot at the end of the rotating line
    final dotPaint = Paint()
      ..color = Colors.black // White dot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, dotPressed ? 12.0 : 6.0, dotPaint);

    // Draw the center dot
    final centerDotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
