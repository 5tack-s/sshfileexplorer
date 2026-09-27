import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sshfileexplorer/controller/sftp_controller.dart';
import 'package:sshfileexplorer/model/file.dart';
import 'package:sshfileexplorer/view/explorer.dart';
import 'package:sshfileexplorer/view/image_window.dart';
import 'package:sshfileexplorer/view/text_window.dart';
import 'package:sshfileexplorer/view/video_window.dart';

import '../controller/prober_controller.dart';
import 'menu.dart';

class Start extends StatelessWidget {
  Start({super.key, required this.pc, required this.sftp}) {
    _router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return Menu(pc: pc);
          },
        ),
        GoRoute(
          path: '/explorer',
          builder: (BuildContext context, GoRouterState state) {
            return Explorer(pc: pc, sftp: sftp);
          },
        ),
        GoRoute(
          path: '/image_window',
          builder: (BuildContext context, GoRouterState state) {
            final imageData = state.extra as File;
            return ImageWindow(image: imageData);
          },
        ),
        GoRoute(
          path: '/video_window',
          builder: (BuildContext context, GoRouterState state) {
            final videoData = state.extra as File;
            return VideoWindow(video: videoData);
          },
        ),
        GoRoute(
          path: '/text_window',
          builder: (BuildContext context, GoRouterState state) {
            final textData = state.extra as File;
            return TextWindow(text: textData);
          },
        ),
      ],
    );
  }

  //will be used throughout the entire application;
  final ProberController pc;
  final SftpController sftp; //though this one depends on the probeservice
  late final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
  }
}
