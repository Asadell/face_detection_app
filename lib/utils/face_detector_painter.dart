import 'package:camera/camera.dart';
import 'package:face_detection_app/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.faces, {
    this.frameSize,
    this.rotation,
    this.cameraLensDirection,
  });

  final List<Face> faces;
  final Size? frameSize;
  final InputImageRotation? rotation;
  final CameraLensDirection? cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = frameSize;
    if (imageSize == null || faces.isEmpty) return;

    final Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..color = Colors.red;

    for (var face in faces) {
      final rect = face.boundingBox;
      final left =
          translateX(rect.left, size, imageSize, rotation, cameraLensDirection);
      final top =
          translateY(rect.top, size, imageSize, rotation, cameraLensDirection);
      final right = translateX(
          rect.right, size, imageSize, rotation, cameraLensDirection);
      final bottom = translateY(
          rect.bottom, size, imageSize, rotation, cameraLensDirection);

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceDetectorPainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
