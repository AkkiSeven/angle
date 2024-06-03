import 'package:flutter/material.dart';
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
      home: const MyHomePage(title: 'Angle Game'),
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
  double _targetAngle = 0.0;
  double _accuracy = 0.0;
  double _totalAccuracy = 0.0;
  int _attempts = 0;
  double _previousTargetAngle = -1.0;
  double _userAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
  }

  void _generateNewTarget() {
    double newTargetAngle;
    do {
      newTargetAngle = Random().nextInt(180).toDouble() + 1; // 1 to 180 degrees
    } while (newTargetAngle == _previousTargetAngle);

    setState(() {
      _previousTargetAngle = newTargetAngle;
      _targetAngle = newTargetAngle;
    });
  }

  void _updateAngle(Offset position) {
    const Offset center = Offset(100, 100);
    double newAngle =
        atan2(center.dy - position.dy, position.dx - center.dx) * 180 / pi;
    if (newAngle < 0) newAngle += 360;

    // Normalize angle to be between 0 and 360
    newAngle = newAngle % 360;

    // Restrict the angle to the top half (0 to 180 degrees)
    if (newAngle > 180) return;

    // Allow slight tolerance for snapping to 0 and 180 degrees
    if (newAngle < 3) newAngle = 0;
    if (newAngle > 177 && newAngle <= 180) newAngle = 180;

    // Snap to 1-degree increments
    newAngle = newAngle.roundToDouble();

    setState(() {
      _angle = newAngle;
    });
  }

  void _calculateAccuracy() {
    setState(() {
      _accuracy = 100 - (((_angle - _targetAngle).abs() / 180) * 100);
      _totalAccuracy += _accuracy;
      _attempts += 1;
      _userAngle = _angle; // Store the user's angle for display
    });
  }

  void _resetAngle() {
    setState(() {
      _angle = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'Target Angle: ${_targetAngle.toStringAsFixed(1)}°',
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
                    const Offset center = Offset(100, 100);
                    final Offset dotCenter = Offset(
                      center.dx + 100 * cos(_angle * pi / 180),
                      center.dy - 100 * sin(_angle * pi / 180),
                    );

                    // Adjusted the touch target area to be more generous
                    if ((details.localPosition - dotCenter).distance <= 24.0) {
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
                    _calculateAccuracy(); // Calculate accuracy after releasing finger
                    _resetAngle(); // Reset angle after releasing finger
                    _generateNewTarget(); // Generate new target angle for the next attempt
                  },
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: AnglePainter(_angle, _dotPressed),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Angle: ${_userAngle.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Accuracy: ${_accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Average Accuracy: ${(_attempts > 0 ? (_totalAccuracy / _attempts) : 0).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.black, fontSize: 20),
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

    // Draw the semicircle (top half)
    final semicirclePaint = Paint()
      ..color = const Color(0xFF212121) // Dark gray
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start angle (180 degrees)
      pi, // Sweep angle (180 degrees)
      false,
      semicirclePaint,
    );

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
      center.dy - radius * sin(radian),
    );

    // Draw the rotating line
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0;
    canvas.drawLine(center, endPoint, linePaint);

    // Draw the dot at the end of the rotating line
    final dotPaint = Paint()
      ..color = Colors.black // Black dot
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
