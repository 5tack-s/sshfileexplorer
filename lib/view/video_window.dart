import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:go_router/go_router.dart';
import 'package:sshfileexplorer/repository/own_repository.dart';

import '../model/file.dart';

class VideoWindow extends StatefulWidget {
  const VideoWindow({super.key, required this.video});
  final File video;
  @override
  State<VideoWindow> createState() => _VideoWindow(video);
}

//dependencies:
//  media_kit: ^1.2.6
//  media_kit_video: ^2.0.1
//  media_kit_libs_video: ^1.0.7
class _VideoWindow extends State<VideoWindow> {
  _VideoWindow(this.video);
  File video;
  late final VideoController controller;
  late final Player player;
  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.open(Media(video.data as String));
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
    _disposeAsync();
  }

  void _disposeAsync() async {
    await OwnRepository.delete(video);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video"),
        leading: IconButton(
          onPressed: () async {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(child: Video(controller: controller)),
          ),
        ],
      ),
    );
  }
}
