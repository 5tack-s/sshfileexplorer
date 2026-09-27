import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';

import '../controller/prober_controller.dart';

class Menu extends StatefulWidget {
  const Menu({super.key, required this.pc});
  final ProberController pc;

  @override
  State<Menu> createState() => _Menu(pc);
}

// ignore: constant_identifier_names
enum _AuthMethod { PUBKEY, PASSWORD }

class _Menu extends State<Menu> {
  ProberController pc;
  _Menu(ProberController pc) : pc = pc;

  _AuthMethod currentAuthMethod = _AuthMethod.PUBKEY;
  final TextEditingController username = TextEditingController();
  final TextEditingController ip = TextEditingController();
  final TextEditingController port = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _connecting = false;
  bool switchForEitherPasswordOrPubkey = true;
  String? _publicKey;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    var key = await pc.getPublicKey();
    setState(() {
      _publicKey = key;
    });
  }

  @override
  void dispose() {
    username.dispose();
    ip.dispose();
    port.dispose();
    super.dispose();
  }

  Widget showAuthenticationFields({required _AuthMethod authMethod}) {
    switch (authMethod) {
      case _AuthMethod.PUBKEY:
        return Column(
          children: [
            TextFormField(
              decoration: InputDecoration(hintText: "Username"),
              controller: username,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "IP Address"),
              controller: ip,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "Port"),
              controller: port,
            ),
          ],
        );
      case _AuthMethod.PASSWORD:
        return Column(
          children: [
            TextFormField(
              decoration: InputDecoration(hintText: "Username"),
              controller: username,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "Password"),
              controller: password,
              obscureText: true,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "IP Address"),
              controller: ip,
            ),
            TextFormField(
              decoration: InputDecoration(hintText: "Port"),
              controller: port,
            ),
          ],
        );
    }
  }

  Future<void> connectKey(String username, String ip, String port) async {
    var parsed = int.tryParse(port);
    if (parsed == null) {
      return;
    }

    setState(() => _connecting = true);
    final ok = await pc.connectKey(username, ip, parsed);
    setState(() => _connecting = false);

    if (!ok) {
      //TODO failed auth
    }
  }

  Future<void> connectPassword(
    String username,
    String password,
    String ip,
    String port,
  ) async {
    var parsed = int.tryParse(port);
    if (parsed == null) {
      return;
    }

    setState(() => _connecting = true);
    final ok = await pc.connectPassword(password, username, ip, parsed);
    setState(() => _connecting = false);

    if (!ok) {
      //TODO failed auth
    }
  }

  Future<void> disconnect() async {
    await pc.disconnect();
  }

  void copyPubkeyToClipboard() async {
    var key = _publicKey;
    if (key != null) {
      await Clipboard.setData(ClipboardData(text: key));
    }
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Menu"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  Text('Current public key: ${_publicKey ?? "Unavailable"}'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Copy public key"),
              onTap: () {
                if (_publicKey != null) {
                  copyPubkeyToClipboard();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text("File Explorer"),
              onTap: () {
                context.push('/explorer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.key),
              title: Text("Generate keypair"),
              onTap: () async {
                var confirmed =
                    await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("WARNING!"),
                          content: const Text(
                            "This option will WIPE your current keypair. Are you sure you wish to continue?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("yup"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text("nah"),
                            ),
                          ],
                        );
                      },
                    ) ??
                    false;

                if (confirmed) {
                  await pc.generateKeyPair();
                  final key = await pc.getPublicKey();
                  setState(() {
                    _publicKey = key;
                  });
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Password"),
                    Switch(
                      value: switchForEitherPasswordOrPubkey,
                      onChanged: (bool value) {
                        switchForEitherPasswordOrPubkey =
                            !switchForEitherPasswordOrPubkey;
                        setState(() {
                          currentAuthMethod = value
                              ? _AuthMethod.PUBKEY
                              : _AuthMethod.PASSWORD;
                        });
                      },
                    ),
                    const Text("Pubkey"),
                  ],
                ),
              ),
            ),

            const Text("Connect to remote ssh server"),
            AnimatedBuilder(
              animation: pc,
              builder: (context, _) {
                return Text(
                  'Connection status: ${pc.isOpen ? 'Connected' : 'Disconnected'}',
                );
              },
            ),
            showAuthenticationFields(authMethod: currentAuthMethod),
            AnimatedBuilder(
              animation: pc,
              builder: (context, _) {
                return ElevatedButton(
                  onPressed: _connecting
                      ? null
                      : pc.isOpen
                      ? disconnect
                      : () {
                          switch (currentAuthMethod) {
                            case _AuthMethod.PASSWORD:
                              connectPassword(
                                username.text,
                                password.text,
                                ip.text,
                                port.text,
                              );
                              break;
                            case _AuthMethod.PUBKEY:
                              connectKey(username.text, ip.text, port.text);
                          }
                        },
                  child: Text(
                    _connecting
                        ? "Connecting..."
                        : pc.isOpen
                        ? "Disconnect"
                        : "Connect",
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
