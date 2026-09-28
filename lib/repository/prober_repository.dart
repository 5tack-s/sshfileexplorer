import "dart:io";

import "package:path_provider/path_provider.dart";
import "package:logger/logger.dart";

class ProberRepository {
  final logger = Logger(printer: PrettyPrinter());

  Future<Directory> _sshDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final sshdir = Directory('${dir.path}/sshfilexplorer/.ssh');
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
      throw FileSystemException;
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
      throw FileSystemException;
    }

    return ed25519Path;
  }

  Future<void> createKnownHosts() async {
    final sshdir = await _sshDir();
    final knownhostsPath = File('${sshdir.path}/known_hosts');
    if (await knownhostsPath.exists()) return;
  }

  Future<void> writeKnownHost(
    String host,
    String type,
    String fingerprint,
  ) async {
    final sshdir = await _sshDir();
    final knownhostsPath = File('${sshdir.path}/known_hosts');
    if (!await knownhostsPath.exists()) {
      await knownhostsPath.create(recursive: true);
    }

    await knownhostsPath.writeAsString(
      '$host $type $fingerprint\n',
      mode: FileMode.append,
    );
  }

  Future<String?> getKnownHostFingerprint(String host, String type) async {
    final sshdir = await _sshDir();

    final knownhostsPath = File('${sshdir.path}/known_hosts');
    if (!await knownhostsPath.exists()) {
      await knownhostsPath.create(recursive: true);
    }

    final lines = await knownhostsPath.readAsLines();
    for (final line in lines) {
      final parts = line.split(' ');
      if (parts.length == 3 && parts[0] == host && parts[1] == type) {
        return parts[2];
      }
    }
    return null;
  }
}
