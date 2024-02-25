import 'package:flutter/material.dart';

class DraggableLines extends StatefulWidget {
  @override
  _DraggableLinesState createState() => _DraggableLinesState();
}

class _DraggableLinesState extends State<DraggableLines> {
  Offset startPointA = Offset(50.0, 50.0);
  Offset endPointA = Offset(250.0, 250.0);

  Offset startPointB = Offset(100.0, 100.0);
  Offset endPointB = Offset(300.0, 300.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          startPointA = Offset(
            startPointA.dx + details.delta.dx,
            startPointA.dy + details.delta.dy,
          );
          endPointA = Offset(
            endPointA.dx + details.delta.dx,
            endPointA.dy + details.delta.dy,
          );

          startPointB = Offset(
            startPointB.dx + details.delta.dx,
            startPointB.dy + details.delta.dy,
          );
          endPointB = Offset(
            endPointB.dx + details.delta.dx,
            endPointB.dy + details.delta.dy,
          );
        });
      },
      child: CustomPaint(
        painter: DraggableLinesPainter(
            startPointA, endPointA, startPointB, endPointB),
        child: Container(),
      ),
    );
  }
}

class DraggableLinesPainter extends CustomPainter {
  final Offset startPointA;
  final Offset endPointA;
  final Offset startPointB;
  final Offset endPointB;

  DraggableLinesPainter(
      this.startPointA, this.endPointA, this.startPointB, this.endPointB);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    // Draw the first line
    canvas.drawLine(startPointA, endPointA, paint);

    // Draw the second line
    canvas.drawLine(startPointB, endPointB, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
