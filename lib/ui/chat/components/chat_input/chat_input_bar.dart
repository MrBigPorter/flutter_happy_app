import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  const ChatInputBar({super.key, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctl = TextEditingController();

  void _submit() {
    final text = _ctl.text;
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.bgSecondary,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctl,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}