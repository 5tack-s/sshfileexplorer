import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sshfileexplorer/controller/prober_controller.dart';
import 'package:sshfileexplorer/controller/sftp_controller.dart';
import 'package:media_kit/media_kit.dart';
import "package:path/path.dart" as p;
import 'package:flutter/services.dart';

import 'view/start.dart';

import 'dart:io';

import 'package:flutter/material.dart';

void main() async {
  MediaKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  final pc = ProberController();
  final sftp = SftpController(pc.ps);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  var temp = await getTemporaryDirectory();
  final cacheDir = Directory(p.join(temp.path, "cache"));

  if (await cacheDir.exists()) {
    await cacheDir.delete(recursive: true);
  }

  await cacheDir.create();

  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'ssh_channel',
      channelName: 'SSH connection status',
      channelDescription: 'notification channel for ssh connectivity',
      defaultColor: const Color.fromARGB(255, 9, 107, 8),
      ledColor: Colors.white,
      playSound: false,
      enableVibration: false,
    ),
  ]);
  runApp(Start(pc: pc, sftp: sftp));
}
