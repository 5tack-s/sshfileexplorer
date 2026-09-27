import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:sshfileexplorer/controller/prober_controller.dart';
import 'package:sshfileexplorer/controller/sftp_controller.dart';
import 'package:path/path.dart' as p;
import 'package:sshfileexplorer/model/file.dart';

class Explorer extends StatefulWidget {
  const Explorer({super.key, required this.sftp, required this.pc});
  final SftpController sftp;
  final ProberController pc;

  @override
  State<Explorer> createState() => _Explorer(sftp, pc);
}

class _Explorer extends State<Explorer> {
  String currentDir = "/";
  final SftpController sftp;
  final ProberController pc;
  Logger logger = Logger();
  List<({SftpFileAttrs attrs, String filename, String longname})>? files;
  _Explorer(this.sftp, this.pc);
  List<Widget> fileNames = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await sftp.start(pc.ps);
    files = await sftp.enterDirectory(await sftp.getCurrentPath());
    updateDirectoryListing();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("File explorer"),
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: updateDirectoryListing,
              icon: Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                highlightColor: const Color.fromARGB(255, 17, 61, 138),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Current directory: $currentDir"),
          ),
          Expanded(child: ListView(children: [...fileNames])),
        ],
      ),
    );
  }

  Future<void> updateDirectoryListing() async {
    var _files = files;
    if (_files == null) {
      print("something odd happened");
      return;
    }

    List<Widget> tiles = [];

    _files.sort((a, b) {
      const special = {'.': 0, '..': 1};

      final aOrder = special[a.filename] ?? 2;
      final bOrder = special[b.filename] ?? 2;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      return a.filename.compareTo(b.filename);
    });

    for (var item in _files) {
      String file = item.filename;
      if (item.attrs.isDirectory) {
        file += '/';
      }

      tiles.add(
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () async {
              if (item.attrs.isFile) {
                var ffile = await sftp.open(await sftp.getCurrentPath() + file);
                switch (ffile.type) {
                  case FileType.video:
                    if (!mounted) return;
                    context.push('video_window', extra: ffile);
                  case FileType.audio:
                    if (!mounted) return;
                    context.push('video_window', extra: ffile);
                  case FileType.text:
                    if (!mounted) return;
                    context.push('text_window', extra: ffile);
                  case FileType.image:
                    if (!mounted) return;
                    context.push('image_window', extra: ffile);
                }
              } else {
                files = await sftp.enterDirectory(
                  '/${await sftp.getCurrentPath()}/$file',
                );
                updateDirectoryListing();
                return;
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 80),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(_getFileIcon(item.attrs.type)),
                  Text(item.filename),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final _cd = await sftp.getCurrentPath();

    setState(() {
      currentDir = _cd;
      fileNames = tiles;
    });
  }

  IconData _getFileIcon(SftpFileType? type) {
    switch (type) {
      case SftpFileType.directory:
        return Icons.folder;
      case SftpFileType.symbolicLink:
        return Icons.link;
      case SftpFileType.blockDevice:
        return Icons.developer_board;
      case SftpFileType.pipe:
        return Icons.compare_arrows;
      case SftpFileType.socket:
        return Icons.settings_ethernet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> updateCurrentDirectory(String path) async {
    currentDir = "${await sftp.getCurrentPath()}/$path";
  }

  @override
  void dispose() {
    super.dispose();
    sftp.clearTrackedFiles();
    sftp.disconnect();
  }
}
