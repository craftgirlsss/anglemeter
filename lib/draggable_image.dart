import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class DragImage extends StatefulWidget {
  final Offset position;
  final File image;

  const DragImage(this.position, this.image, {super.key});

  @override
  DragImageState createState() => DragImageState();
}

class DragImageState extends State<DragImage> {
  double? _zoom;
  double? _previousZoom;
  Offset? previousOffset;
  Offset? _offset;
  Offset? _position;
  File? _image;

  @override
  void initState() {
    _zoom = 1.0;
    _previousZoom = null;
    _offset = Offset.zero;
    _position = widget.position;
    _image = widget.image;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position?.dx, //horizontal
      top: _position?.dy, //vertical
      child: Draggable(
        //drag and drop

        onDraggableCanceled: (velocity, offset) {
          //When you stop moving the image, it is necessary to setState the new coordinates
          setState(() {
            _position = offset;
          });
        },

        feedback: Container(
          //Response when moving the image. Increase the width and height to 100.0 to see the difference
          width: 1.0,
          height: 1.0,
          child: Image.file(_image!),
        ),
        child: Container(
          padding: const EdgeInsets.all(10.0),
          width: 350.0,
          height: 450.0,
          child: GestureDetector(
            //zoom
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onDoubleTap: _handleScaleReset,
            child: Transform(
              transform:
                  Matrix4.diagonal3(vector.Vector3(_zoom!, _zoom!, _zoom!)),
              alignment: FractionalOffset.center,
              child: Image.file(_image!),
            ),
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails start) {
    setState(() {
      previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails update) {
    setState(() {
      _zoom = _previousZoom! * update.scale;
    });
  }

  void _handleScaleReset() {
    setState(() {
      _zoom = 1.0;
      _offset = Offset.zero;
      _position = Offset.zero;
    });
  }
}
