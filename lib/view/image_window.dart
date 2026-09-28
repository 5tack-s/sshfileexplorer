import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sshfileexplorer/model/file.dart';
import 'package:sshfileexplorer/repository/own_repository.dart';

class ImageWindow extends StatelessWidget {
  const ImageWindow({super.key, required this.image});
  final File image;

  /*
Note:
InteractiveViewer(
  minScale: 1.0,
  maxScale: 4.0,
  child: Image.asset('assets/photo.jpg'),
)

actually no this only works on mobile
try this: https://pub.dev/packages/interactive_viewer_2
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image"),
        leading: IconButton(
          onPressed: () async {
            //await OwnRepository.delete(image);
            if (!context.mounted) return;
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.memory(image.data as Uint8List),
            ),
          ),
        ],
      ),
    );
  }
}
