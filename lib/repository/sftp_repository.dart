import "dart:io";
import "dart:isolate";

import "package:dartssh2/dartssh2.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import 'package:flutter/material.dart';

class SftpRepository {
  final _trackedFiles = [];
  final ValueNotifier downloadProgress = ValueNotifier<int>(0);

  void trackDownload(int progress) {
    downloadProgress.value = progress;
    print(downloadProgress.value);
  }

  Future<String> downloadToTemp(SftpClient sftp, String remote) async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory("${tempDir.path}/cache");
    final local = p.join(cacheDir.path, p.basename(remote));
    final output = File(local).openWrite();

    _trackedFiles.add(local);
    await sftp.download(
      remote,
      output,
      closeDestination: true,
      onProgress: trackDownload,
    );

    return local;
  }

  //call this to clear all the "cached" files
  Future<void> deleteTrackedFiles() async {
    for (var path in _trackedFiles) {
      var file = File(path);
      if (await file.exists()) {
        file.delete();
      }
    }
    _trackedFiles.clear();
  }
}
