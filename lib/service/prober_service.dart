import 'package:dartssh2/dartssh2.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../repository/prober_repository.dart';

class ProberService {
  final int statusNotificationId = 0;
  SSHClient? session;
  ({String ip, int port, String username})? user;
  Ed25519 ed25519;
  final ValueNotifier<bool> isOpenNotifier = ValueNotifier(false);
  Logger logger = Logger();
  ProberService() : ed25519 = Ed25519();

  void _setOpen(bool value) {
    isOpenNotifier.value = value;
  }

  void _watchConnection(SSHClient client) {
    client.done.then((_) {
      if (identical(session, client)) {
        session = null;

        _setOpen(false);
      }
    });
  }

  void dispose() {
    session?.close();
    isOpenNotifier.dispose();
  }

  Future<void> disconnect() async {
    final client = session;
    session = null;
    user = null;

    _setOpen(false);
    client?.close();
    await AwesomeNotifications().cancel(statusNotificationId);
  }

  Future<bool> connectPassword(
    String? password,
    String username,
    String host, [
    int port = 22,
  ]) async {
    try {
      await disconnect();

      var client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );

      await client.authenticated;

      user = (ip: host, port: port, username: username);

      session = client;
      _setOpen(true);
      _watchConnection(client);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: statusNotificationId,
          channelKey: 'channelKey',
          title: 'Client is connected to $host',
          body: null,
          locked: true,
          autoDismissible: false,
        ),
      );
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> connectKey(String username, String host, [int port = 22]) async {
    final ed25519file = await ProberRepository().getPrivateKeyFile();
    try {
      await disconnect();

      var client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        identities: [...SSHKeyPair.fromPem(await ed25519file.readAsString())],
      );

      await client.authenticated;

      user = (ip: host, port: port, username: username);
      session = client;
      _setOpen(true);
      _watchConnection(client);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: statusNotificationId,
          channelKey: 'channelKey',
          title: 'Client is connected to $host',
          body: null,
          locked: true,
          autoDismissible: false,
        ),
      );

      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<void> generateKeypair() async {
    final keyPair = await ed25519.newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicBytes = publicKey.bytes;

    final privatePem = encodeEd25519Private(
      privateBytes: privateBytes,
      publicBytes: publicBytes,
    );

    final publicOpenSsh = encodeEd25519Public(publicBytes);

    await ProberRepository().writePem("id_ed25519", privatePem);
    await ProberRepository().writePem("id_ed25519.pub", publicOpenSsh);
  }

  Future<String?> getPublicKey() async {
    return await ProberRepository().getPublicKey();
  }

  ({String ip, int port, String username})? getUser() {
    var _u = user;
    if (_u == null) return null;

    return _u;
  }
}
