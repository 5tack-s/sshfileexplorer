import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:openssh_ed25519/openssh_ed25519.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../repository/prober_repository.dart';
import '../view/navigator_key.dart';

class ProberService {
  final int statusNotificationId = 0;
  SSHClient? session;
  ({String ip, int port, String username})? user;
  final Ed25519 ed25519 = Ed25519();
  final ValueNotifier<bool> isOpenNotifier = ValueNotifier(false);
  Logger logger = Logger();
  final ProberRepository _proberRepository = ProberRepository();
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

  Future<bool> _onUnknownKey(String type, String key) async {
    final context = navigatorKey.currentContext;
    if (context == null) return false;

    final result =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Unknown Host Key!"),
            content: Text("Host's $type key is $key. Accept?"),
            actions: [
              TextButton(
                child: Text("No"),
                onPressed: () => Navigator.pop(context, false),
              ),

              TextButton(
                child: Text("Yes"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    return result;
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
        onVerifyHostKey: (String type, Uint8List fingerprint) async {
          final expectedFingerprint = await _proberRepository
              .getKnownHostFingerprint(host, type);
          final fp = formatFingerprint(fingerprint);
          if (expectedFingerprint == null) {
            final trusted = await _onUnknownKey(type, fp);
            if (trusted) {
              await _proberRepository.writeKnownHost(host, type, fp);
            }
            return trusted;
          }
          return expectedFingerprint == fp;
        },
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

  String formatFingerprint(Uint8List fp) {
    final b = base64.encode(fp).replaceAll('=', '');
    return 'SHA256:$b';
  }

  Future<bool> connectKey(String username, String host, [int port = 22]) async {
    final ed25519file = await _proberRepository.getPrivateKeyFile();
    try {
      await disconnect();

      var client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        identities: [...SSHKeyPair.fromPem(await ed25519file.readAsString())],
        onVerifyHostKey: (String type, Uint8List fingerprint) async {
          final expectedFingerprint = await _proberRepository
              .getKnownHostFingerprint(host, type);
          final fp = formatFingerprint(fingerprint);
          if (expectedFingerprint == null) {
            final trusted = await _onUnknownKey(type, fp);
            if (trusted) {
              await _proberRepository.writeKnownHost(host, type, fp);
            }
            return trusted;
          }
          return expectedFingerprint == fp;
        },
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

    await _proberRepository.writePem("id_ed25519", privatePem);
    await _proberRepository.writePem("id_ed25519.pub", publicOpenSsh);
  }

  Future<String?> getPublicKey() async {
    return await _proberRepository.getPublicKey();
  }

  ({String ip, int port, String username})? getUser() {
    var _u = user;
    if (_u == null) return null;

    return _u;
  }
}
