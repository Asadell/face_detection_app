import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector;

  FaceDetectionService([
    FaceDetector? faceDetector,
  ]) : _faceDetector = faceDetector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableContours:
                    false, //mengaktifkan sistem identifikasi kontur atau garis tepi wajah. Kontur memberikan detail yang lebih lengkap tentang bentuk dan struktur wajah.
                enableLandmarks:
                    false, //mengaktifkan sistem identifikasi titik penting pada wajah, seperti mata, hidung, dan ujung bibir. Landmark membantu mengidentifikasi posisi spesifik fitur wajah.
              ),
            );

  Future<List<Face>> runDetectingFaces(InputImage inputImage) async {
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    return faces;
  }

  Future<void> close() {
    return _faceDetector.close();
  }
}
