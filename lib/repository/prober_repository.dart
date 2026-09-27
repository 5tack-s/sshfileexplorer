import "dart:io";

import "package:path_provider/path_provider.dart";
import "package:logger/logger.dart";

class ProberRepository {
  final logger = Logger(printer: PrettyPrinter());

  Future<Directory> _sshDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final sshdir = Directory('${dir.path}/.ssh');
    if (!await sshdir.exists()) {
      await sshdir.create(recursive: true);
    }
    return sshdir;
  }

  //storing ssh authentication keys
  Future<void> writePem(String path, String content) async {
    try {
      final sshdir = await _sshDir();

      if (!await sshdir.exists()) {
        await sshdir.create(recursive: false);
      }

      await File('${sshdir.path}/$path').writeAsString(content);
    } catch (e) {
      logger.e(e);
      throw IOException;
    }
  }

  Future<String?> getPublicKey() async {
    try {
      final sshdir = await _sshDir();

      final pub = File('${sshdir.path}/id_ed25519.pub');
      if (!await pub.exists()) {
        return null;
      }

      return await pub.readAsString();
    } catch (e) {
      logger.e(e);
      return null;
    }
  }

  Future<File> getPrivateKeyFile() async {
    final sshdir = await _sshDir();
    final ed25519Path = File('${sshdir.path}/id_ed25519');
    if (!await ed25519Path.exists()) {
      throw IOException;
    }

    return ed25519Path;
  }
}
