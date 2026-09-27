import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sshfileexplorer/model/file.dart';

class TextWindow extends StatefulWidget {
  const TextWindow({super.key, required this.text});
  final File text;

  @override
  State<StatefulWidget> createState() {
    return _TextWindow(text);
  }
}

class _TextWindow extends State<TextWindow> {
  _TextWindow(this.text);

  final File text;
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: text.data as String);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Text"),
        leading: IconButton(
          onPressed: () async {
            if (!context.mounted) return;
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: EditableText(
              maxLines: null,
              controller: _controller,
              keyboardType: TextInputType.multiline,
              scrollPadding: EdgeInsets.all(20.0),
              focusNode: _focus,
              style: TextStyle(fontSize: 12, color: Colors.white),
              cursorColor: Colors.black,
              backgroundCursorColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
