import 'package:face_detection_app/controller/camera_provider.dart';
import 'package:face_detection_app/utils/face_detector_painter.dart';
import 'package:face_detection_app/widget/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraPage extends StatelessWidget {
  const CameraPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Face Detection App'),
      ),
      body: Consumer<CameraProvider>(
        builder: (context, value, child) {
          final faces = value.faces;
          final inputImage = value.inputImage;
          final cameraLensDirection = value.cameraLensDirection;

          return CustomPaint(
            foregroundPainter: FaceDetectorPainter(
              faces,
              frameSize: inputImage?.metadata?.size,
              rotation: inputImage?.metadata?.rotation,
              cameraLensDirection: cameraLensDirection,
            ),
            child: child,
          );
        },
        child: CameraView(
          onImage: (inputImage) async {
            final cameraProvider = context.read<CameraProvider>();
            await cameraProvider.detectingFacesStream(inputImage);
          },
          onCameraLensDirectionChanged: (direction) {
            final cameraProvider = context.read<CameraProvider>();
            cameraProvider.cameraLensDirection = direction;
          },
        ),
      ),
    );
  }
}
