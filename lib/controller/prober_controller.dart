import 'package:flutter/material.dart';

import '../service/prober_service.dart';

class ProberController extends ChangeNotifier {
  final ProberService ps = ProberService();

  ProberController() {
    ps.isOpenNotifier.addListener(_onOpenChanged);
  }

  bool get isOpen => ps.isOpenNotifier.value;

  void _onOpenChanged() {
    notifyListeners();
  }

  Future<bool> connectPassword(
    String? password,
    String username,
    String host,
    int port,
  ) async {
    var status = await ps.connectPassword(password, username, host, port);
    return status;
  }

  Future<void> disconnect() async {
    await ps.disconnect();
  }

  Future<bool> connectKey(String username, String host, int port) async {
    var status = await ps.connectKey(username, host, port);
    return status;
  }

  Future<void> generateKeyPair() async {
    await ps.generateKeypair();
  }

  Future<String?> getPublicKey() async {
    return await ps.getPublicKey();
  }

  @override
  void dispose() {
    ps.isOpenNotifier.removeListener(_onOpenChanged);
    ps.dispose();
    super.dispose();
  }
}
