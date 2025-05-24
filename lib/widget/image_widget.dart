import 'dart:io';

import 'package:flutter/material.dart';

class ImageWidget extends StatelessWidget {
  final File? imageFile;
  const ImageWidget({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return imageFile == null
        ? const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.image,
              size: 100,
            ),
          )
        : Image.file(
            imageFile!,
            fit: BoxFit.contain,
          );
  }
}
