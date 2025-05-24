import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraView extends StatefulWidget {
  final Function(InputImage inputImage)? onImage;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;

  const CameraView({
    super.key,
    this.onImage,
    this.onCameraLensDirectionChanged,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  bool _isCameraInitialized = false;

  List<CameraDescription> _cameras = [];

  CameraController? controller;

  bool _isBackCameraSelected = true;

  bool _isProcessing = false;

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    final cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    await previousCameraController?.dispose();

    cameraController.initialize().then((value) {
      if (mounted) {
        setState(() {
          controller = cameraController;
          if (widget.onImage != null) {
            controller!.startImageStream(_processCameraImage);
          }
          if (widget.onCameraLensDirectionChanged != null) {
            widget
                .onCameraLensDirectionChanged!(cameraDescription.lensDirection);
          }
          _isCameraInitialized = controller!.value.isInitialized;
        });
      }
    }).catchError((e) {
      print('Error initializing camera: $e');
    });
  }

  void initCamera() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    await onNewCameraSelected(_cameras.first);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    if (widget.onImage != null) {
      final camera = _cameras[_isBackCameraSelected ? 0 : 1];
      final inputImage = inputImageFromCameraImage(camera, image);
      if (inputImage != null) {
        await widget.onImage!(inputImage);
      }
    }
    _isProcessing = false;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    initCamera();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    controller!
      ..stopImageStream()
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController != null || !cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
        cameraController.dispose();
        break;
      case AppLifecycleState.resumed:
        onNewCameraSelected(cameraController.description);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _isCameraInitialized
            ? CameraPreview(controller!)
            : const Center(child: CircularProgressIndicator()),
        Align(
          alignment: const Alignment(0.9, 0.9),
          child: FloatingActionButton(
            heroTag: "switch-camera",
            tooltip: "Switch Camera",
            onPressed: () => _onCameraSwitch(),
            child: const Icon(Icons.cameraswitch),
          ),
        ),
      ],
    );
  }

  void _onCameraSwitch() {
    if (_cameras.length == 1) return;

    setState(() {
      _isCameraInitialized = false;
    });

    onNewCameraSelected(
      _cameras[_isBackCameraSelected ? 1 : 0],
    );

    setState(() {
      _isBackCameraSelected = !_isBackCameraSelected;
    });
  }

  InputImage? inputImageFromCameraImage(
    CameraDescription camera,
    CameraImage image,
  ) {
    // get sensor orientation
    final sensorOrientation = camera.sensorOrientation;

    // get image rotation
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      // assume the phone is potrait [DeviceOrientation.portraitUp]
      var rotationCompensation = 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // get image plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
