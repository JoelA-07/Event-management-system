import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMsg = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": userMsg});
      _isTyping = true;
    });
    _controller.clear();

    try {
      final response = await Dio().post("${AppConstants.baseUrl}/ai/chat", data: {
        "message": userMsg,
        "contextHalls": [] // You can pass your hall list here later
      });

      setState(() {
        _messages.add({"role": "assistant", "text": response.data['reply']});
        _isTyping = false;
      });
    } catch (e) {
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Elite AI Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _messages[index]['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: Text("Assistant is typing...")),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Ask about a hall or package..."))),
                IconButton(icon: const Icon(Icons.send, color: AppTheme.primaryColor), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}