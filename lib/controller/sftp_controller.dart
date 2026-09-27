// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dartssh2/dartssh2.dart';
import 'package:sshfileexplorer/service/prober_service.dart';
import 'package:path/path.dart' as p;

import '../model/file.dart';
import '../service/sftp_service.dart';

class SftpController {
  final ProberService ps;
  SftpService? ss;

  SftpController(this.ps);

  Future<List<({String filename, String longname, SftpFileAttrs attrs})>?>
  enterDirectory(String path) async {
    var _ss = ss;
    if (_ss == null) return null;
    var attrs = await _ss.getFileProperties(path);
    if (attrs.isDirectory) {
      return await _ss.getDirectories(path);
    }
    return null;
  }

  Future<void> start(ProberService ps) async {
    var _ss = SftpService(ps);
    ss = _ss;
    await _ss.connect();
  }

  void disconnect() {
    var _ss = ss;
    if (_ss == null) return;
    _ss.disconnect();
    ss = null;
  }

  Future<String> getCurrentPath() async {
    var _ss = ss;
    if (_ss == null) return '';
    return _ss.getCurrentDirectory();
  }

  Future<File> open(String file) async {
    var _ss = ss;
    if (_ss == null) throw ArgumentError("sftp session was never initialized");

    var video = {
      '.mp4',
      '.mkv',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.mpeg',
      '.mpg',
      '.m4v',
    };

    var audio = {
      '.mp3',
      '.wav',
      '.ogg',
      '.flac',
      '.aac',
      '.wma',
      '.m4a',
      '.alac',
      '.aiff',
      '.opus',
    };

    var image = {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
      '.tif',
      '.ico',
    };

    var ext = p.extension(file);
    var t = video.contains(ext)
        ? FileType.video
        : audio.contains(ext)
        ? FileType.audio
        : image.contains(ext)
        ? FileType.image
        : FileType.text;

    switch (t) {
      case FileType.image:
        return await _ss.openImage(file);
      case FileType.video:
        return await _ss.openVideo(file);
      case FileType.text:
        return await _ss.openText(file);
      case FileType.audio:
        return await _ss.openAudio(file);
    }
  }

  Future<void> clearTrackedFiles() async {
    var _ss = ss;
    if (_ss == null) throw ArgumentError("sftp session was never initialized");

    await _ss.sftpRepository.deleteTrackedFiles();
  }
}
