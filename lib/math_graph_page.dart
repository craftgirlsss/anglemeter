import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:superdeclarative_geometry/superdeclarative_geometry.dart';

import '_point_ext.dart';
import '_reorienting_gesture_detector.dart';

class MathGraphPage extends StatefulWidget {
  const MathGraphPage({super.key});

  @override
  _MathGraphPageState createState() => _MathGraphPageState();
}

class _MathGraphPageState extends State<MathGraphPage>
    with SingleTickerProviderStateMixin {
  Image? backgroundImage;
  final CartesianOrientation _graphOrientation = CartesianOrientation.math;
  PolarCoord _polarCoord = const PolarCoord(150, Angle.fromDegrees(145));

  // File? imagegallery;
  // String? filename;
  // List<File> filePersonal = [];
  // String? pathProfile;
  // getFromGallery() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? imagePicked =
  //       await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
  //   setState(() {
  //     imagegallery = File(imagePicked!.path);
  //     filename = imagePicked.name;
  //     filePersonal.add(imagegallery!);
  //     pathProfile = imagePicked.path;
  //     print("ini file path ganti profile photo $pathProfile");
  //   });
  // }

  Future<ui.Image> get getImage async {
    final completer = Completer<ui.Image>();
    if (!Platform.isAndroid && !Platform.isIOS) {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (file != null) {
        final filePath = file.files.single.path;
        final bytes = filePath == null
            ? file.files.first.bytes
            : File(filePath).readAsBytesSync();
        if (bytes != null) {
          completer.complete(decodeImageFromList(bytes));
        } else {
          completer.completeError('No image selected');
        }
      }
    } else {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        completer.complete(
          decodeImageFromList(bytes),
        );
      } else {
        completer.completeError('No image selected');
      }
    }
    setState(() {});

    return completer.future;
  }

  Future<Uint8List?> getBytes({GlobalKey? canvasGlobalKey}) async {
    RenderRepaintBoundary boundary = canvasGlobalKey!.currentContext
        ?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                if (backgroundImage != null) {
                  setState(() {
                    backgroundImage = null;
                  });
                } else {
                  setState(() async {
                    backgroundImage = await getImage;
                  });
                }
              },
              icon: const Icon(
                Icons.image,
                color: Colors.black54,
              ))
        ],
        centerTitle: true,
        title: const Text(
          'Geometry',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Container(
          //     child: PhotoView(
          //   imageProvider: FileImage(backgroundImage),
          // )),
          Column(
            children: [
              // _buildOrientationTabs(),
              Expanded(
                child: DraggablePolarCoordGraph(
                    backgroundImage: backgroundImage,
                    graphOrientation: _graphOrientation,
                    polarCoord: _polarCoord,
                    onPolarCoordChange: (PolarCoord newCoord) {
                      setState(() {
                        _polarCoord = newCoord;
                      });
                    }),
              ),
              backgroundImage != null ? _buildCoordinateInfo() : Container(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sudut Kemiringan= ${_polarCoord.angle.makePositive().degrees.round()}°',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Metode 1 = ${_polarCoord.angle.complement}",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Metode 2 = ${_polarCoord.angle.percent}",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a draggable `PolarCoord` on graph paper, drawing the angle between
/// the zero-axis and the `PolarCoord`, as well as the complementary angle.
class DraggablePolarCoordGraph extends StatefulWidget {
  final Image? backgroundImage;
  const DraggablePolarCoordGraph({
    Key? key,
    required this.graphOrientation,
    this.polarCoord = const PolarCoord(100, Angle.zero),
    this.onPolarCoordChange,
    this.backgroundImage,
  }) : super(key: key);

  final CartesianOrientation graphOrientation;
  final PolarCoord polarCoord;
  final void Function(PolarCoord)? onPolarCoordChange;

  @override
  _DraggablePolarCoordGraphState createState() =>
      _DraggablePolarCoordGraphState();
}

class _DraggablePolarCoordGraphState extends State<DraggablePolarCoordGraph> {
  final double _touchDotRadius = 200;

  Offset? _startDragTouchVector;
  Offset? _startDragTouchImage;
  PolarCoord? _startDragPolarCoord;
  Offset? _currentDragTouchVector;
  Offset? _currentDragTouchImage;
  double? zoom;
  double? previousZoom;
  Offset? previousOffset;
  Offset? offset;
  Offset? position;

  @override
  void initState() {
    super.initState();
    if (widget.backgroundImage != null) {
      zoom = 1.0;
      previousOffset = null;
      offset = Offset.zero;
      position = const Offset(0, 0);
    }
  }

  void handleScaleStart(ScaleStartDetails start) {
    setState(() {
      previousOffset = offset;
      previousZoom = zoom;
    });
  }

  void handleScaleUpdate(ScaleUpdateDetails update) {
    setState(() {
      zoom = previousZoom! * update.scale;
    });
  }

  void handleScaleReset() {
    setState(() {
      zoom = 1.0;
      offset = Offset.zero;
      position = Offset.zero;
    });
  }

  // image drag start awal coba
  void _onDragImageStart(DragStartDetails details) {
    _startDragTouchImage = details.localPosition;
  }

  // image drag update coba
  void _onDragImageUpdate(details) {
    _currentDragTouchImage = details.localPosition;
    final dragDeltaOffset = _currentDragTouchImage! - _startDragTouchImage!;
    final dragDeltaPoint = Point(dragDeltaOffset.dx, dragDeltaOffset.dy);
    setState(() {
      dragDeltaPoint;
    });
  }

  void _onDragStart(DragStartDetails details) {
    _startDragTouchVector = details.localPosition;
    _startDragPolarCoord = widget.polarCoord;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _currentDragTouchVector = details.localPosition;
    final dragDeltaOffset = _currentDragTouchVector! - _startDragTouchVector!;
    final dragDeltaPoint = Point(dragDeltaOffset.dx, dragDeltaOffset.dy);

    setState(() {
      widget.onPolarCoordChange?.call(
        _startDragPolarCoord!.moveInCartesianSpace(
          dragDeltaPoint,
          orientation: widget.graphOrientation,
        ),
      );
    });
  }

  Offset _mapDragPointToCartesianOrientation(Offset localOffset) {
    return localOffset
        .toPoint()
        // transform the point from screen space to the desired CartesianOrientation.
        .fromScreenTo(widget.graphOrientation)
        .toOffset();
  }

  Offset _computeDotPosition(Size widgetSize) {
    final center = widgetSize.center(Offset.zero);
    return widget.polarCoord
        .toCartesian(orientation: widget.graphOrientation)
        .toScreenPoint(fromOrientation: widget.graphOrientation)
        .toOffset()
        .translate(-_touchDotRadius, -_touchDotRadius)
        .translate(center.dx, center.dy);
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.backgroundImage != null) {
    //   zoom = 1.0;
    //   previousOffset = null;
    //   offset = Offset.zero;
    //   position = const Offset(0, 0);
    // }
    return LayoutBuilder(builder: (context, constraints) {
      final dotPosition = _computeDotPosition(constraints.biggest);
      return Stack(
        children: [
          widget.backgroundImage != null
              ? _buildGraph()
              : const Center(
                  child: Text(
                    "Tidak ada gambar dalam \nworkspaces",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                ),
          Positioned(
            left: dotPosition.dx,
            top: dotPosition.dy,
            child: _buildDragTouchTarget(),
          ),
        ],
      );
    });
  }

  Widget _buildGraph() {
    return CustomPaint(
      painter: _GraphPainter(
        backgroundImages: widget.backgroundImage,
        graphOrientation: widget.graphOrientation,
        polarCoord: widget.polarCoord,
        backgroundColor: const Color(0xFF44AAFF),
        primaryLineColor: const Color(0xFFAACCFF),
        secondaryLineColor: const Color(0xFF66BBFF),
        primaryAngleColor: Colors.white.withOpacity(0.3),
        complementaryAngleColor: Colors.transparent,
        vectorColor: Colors.white,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildDragTouchTarget() {
    return ReorientedGestureDetector(
      origin: ReorientedGestureDetector.originAtCenter,
      pointMapper: _mapDragPointToCartesianOrientation,
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      child: Container(
        width: 3 * _touchDotRadius,
        height: 3 * _touchDotRadius,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDragTouchTargetImage() {
    return GestureDetector(
      onPanStart: _onDragImageStart,
      onPanUpdate: _onDragImageUpdate,
      child: Container(),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final Image? backgroundImages;
  _GraphPainter({
    CartesianOrientation graphOrientation = CartesianOrientation.math,
    required PolarCoord polarCoord,
    Key? key,
    this.backgroundImages,
    Color backgroundColor = Colors.white,
    Color primaryLineColor = const Color(0xFFAAAAAA),
    Color secondaryLineColor = const Color(0xFFDDDDDD),
    Color vectorColor = Colors.red,
    Color primaryAngleColor = const Color(0xFF44AAFF),
    Color complementaryAngleColor = const Color(0xFF44AAFF),
  })  : _graphOrientation = graphOrientation,
        _polarCoord = polarCoord,
        _bkPaint = Paint()..color = backgroundColor,
        _primaryLinePaint = Paint()
          ..color = primaryLineColor
          ..strokeWidth = 0.8,
        _secondaryLinePaint = Paint()
          ..color = secondaryLineColor
          ..strokeWidth = 2,
        _vectorPaint = Paint()
          ..color = vectorColor
          ..strokeJoin
          ..strokeWidth = 2,
        _primaryAnglePaint = Paint()
          ..color = primaryAngleColor
          ..strokeWidth = 1,
        _complementaryAnglePaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = complementaryAngleColor
          ..strokeWidth = 0.8;

  final CartesianOrientation _graphOrientation;
  final PolarCoord _polarCoord;
  // final Image? backgroundImage;
  final double _lineSpacing = 10;

  final Paint _bkPaint;
  final Paint _primaryLinePaint;
  final Paint _secondaryLinePaint;

  final Paint _vectorPaint;
  final Paint _primaryAnglePaint;
  final Paint _complementaryAnglePaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImages != null) {
      canvas.drawImageRect(
        backgroundImages!,
        Rect.fromLTWH(0, 0, backgroundImages!.width.toDouble(),
            backgroundImages!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }

    _paintGraph(canvas, size);

    _paintPolarCoord(canvas, size, _polarCoord);
  }

  void _paintGraph(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Draw the zero axis for the given orientation.
    if (_graphOrientation == CartesianOrientation.math ||
        _graphOrientation == CartesianOrientation.screen) {
      canvas.drawLine(
        Offset(center.dx / 2, center.dy),
        Offset(size.width, center.dy),
        _vectorPaint,
      );
    }
  }

  void _paintPolarCoord(Canvas canvas, Size size, PolarCoord polarCoord) {
    final center = size.center(Offset.zero);
    final primaryAngleSegmentRadius = _polarCoord.radius * 0.2;
    final complementaryAngleSegmentRadius = _polarCoord.radius * 0.8;

    // Convert the polarCoord to an Offset that can be painted on the screen.
    final Offset vector = polarCoord
        // (x, y) of the polar coord as seen in the graph's coord system
        .toCartesian(orientation: _graphOrientation)
        // (x, y) of the polar coord as seen in the screen's coord system
        .toScreenPoint(fromOrientation: _graphOrientation)
        // convert to an Offset so that Flutter can use this point
        .toOffset()
        // use center point as origin, instead of upper left
        .translate(center.dx, center.dy);

    // We want the graph to always paint our angle in the positive direction
    // all the way around, so make it positive.
    final primaryAngle = polarCoord.angle.makePositive();
    final Angle primaryAngleStart = _graphOrientation.toScreenAngle(Angle.zero);
    final Angle primaryAngleSweep =
        _graphOrientation.toScreenAngle(primaryAngle) - primaryAngleStart;
    final Angle complementaryAngleStart = primaryAngleSweep + primaryAngleStart;
    final Angle complementaryAngleSweep = primaryAngleSweep.complement;

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: 1.9 * primaryAngleSegmentRadius,
        height: 1.9 * primaryAngleSegmentRadius,
      ),
      primaryAngleStart.radians.toDouble(),
      primaryAngleSweep.radians.toDouble(),
      true,
      _primaryAnglePaint,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: 1 * complementaryAngleSegmentRadius,
        height: 1 * complementaryAngleSegmentRadius,
      ),
      complementaryAngleStart.radians.toDouble(),
      complementaryAngleSweep.radians.toDouble(),
      false,
      _complementaryAnglePaint,
    );

    // Paint a ray from the origin of the graph to the polarCoord.
    canvas.drawLine(
      center,
      vector,
      _vectorPaint,
    );
    canvas.drawCircle(center, 8, _vectorPaint);
    canvas.drawCircle(vector, 8, _vectorPaint);
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return _graphOrientation != oldDelegate._graphOrientation ||
        _polarCoord != oldDelegate._polarCoord ||
        _lineSpacing != oldDelegate._lineSpacing ||
        _bkPaint.color != oldDelegate._bkPaint.color ||
        _primaryLinePaint.color != oldDelegate._primaryLinePaint.color ||
        _secondaryLinePaint.color != oldDelegate._secondaryLinePaint.color ||
        _vectorPaint.color != oldDelegate._vectorPaint.color ||
        _primaryAnglePaint.color != oldDelegate._primaryAnglePaint.color ||
        _complementaryAnglePaint.color !=
            oldDelegate._complementaryAnglePaint.color;
  }
}
