import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:logger/logger.dart';
import 'package:sshfileexplorer/model/file.dart';
import 'package:flutter/material.dart';

import 'prober_service.dart';

import 'package:path/path.dart' as p;

import '../repository/sftp_repository.dart';

class SftpService {
  SftpService(this.ps);
  late final ProberService ps;
  late SftpClient sftp;
  Logger logger = Logger();
  late String _currentPath;
  final SftpRepository sftpRepository = SftpRepository();

  Future<void> connect() async {
    final session = ps.session;
    if (session == null) {
      logger.e(
        "SESSION HASNT STARTED. You have to start an ssh session first!!",
      );
      return;
    }
    sftp = await session.sftp();
    _currentPath = await sftp.absolute(".");
  }

  Future<SftpFileAttrs> getFileProperties(String path) async {
    return await sftp.stat(path);
  }

  Future<List<({String filename, String longname, SftpFileAttrs attrs})>>
  getDirectories(String path) async {
    final newPath = p.normalize(p.join(_currentPath, path));

    try {
      var items = await sftp.listdir(newPath);
      _currentPath = newPath.endsWith("/") ? newPath : "$newPath/";

      List<({String filename, String longname, SftpFileAttrs attrs})>
      concreteDirectoryNames = [];
      for (var item in items) {
        concreteDirectoryNames.add((
          filename: item.filename,
          longname: item.longname,
          attrs: item.attr,
        ));
      }

      return concreteDirectoryNames;
    } catch (e) {
      logger.e(e);
      return <({String filename, String longname, SftpFileAttrs attrs})>[];
    }
  }

  Future<File> openImage(String path) async {
    final ext = p.extension(path).toLowerCase();
    final Set<String> imageExt = {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.webp',
    };

    if (imageExt.contains(ext)) {
      var file = await sftp.open(path);
      final bytes = await file.readBytes();
      await file.close();

      return File(data: bytes, type: FileType.image, path: path);
    }

    throw ArgumentError("Invalid image extension.");
  }

  Future<File> openVideo(String path) async {
    final Set<String> videoExt = {
      '.mp4',
      '.mov',
      '.avi',
      '.mpeg',
      '.webm',
      '.mkv',
    };
    final ext = p.extension(path).toLowerCase();

    if (videoExt.contains(ext)) {
      var local = await sftpRepository.downloadToTemp(sftp, path);
      return File(path: local, data: local, type: FileType.video);
    }

    throw ArgumentError("Invalid video extension.");
  }

  Future<File> openText(String path) async {
    //just anything can open as text right?

    var file = await sftp.open(path);
    final bytes = await file.readBytes();
    final decoded = utf8.decode(bytes, allowMalformed: true);
    await file.close();

    return File(path: path, data: decoded, type: FileType.text);
  }

  Future<File> openAudio(String path) async {
    var local = await sftpRepository.downloadToTemp(sftp, path);
    return File(path: local, data: local, type: FileType.audio);
  }

  String getCurrentDirectory() {
    return _currentPath;
  }

  void disconnect() {
    sftp.close();
  }
}
