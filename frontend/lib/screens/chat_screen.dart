import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/input_box.dart';
import '../widgets/typing_bubble.dart';
import '../services/gemini_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];
  final ScrollController _scrollController = ScrollController();

  final GeminiService geminiService = GeminiService();
  final FlutterTts flutterTts = FlutterTts();

  bool isTyping = false;
  bool hasSpoken = false;
  bool isSpeakerOn = true;

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await geminiService.generateResponse(text);

      String streamedText = "";

      setState(() {
        messages.add({"role": "ai", "text": ""});
        hasSpoken = false;
      });

      int lastIndex = messages.length - 1;

      await simulateTyping(response, (partial) {
        streamedText = partial;

        setState(() {
          messages[lastIndex]["text"] = streamedText;
        });

        _scrollToBottom();
      });

      if (!hasSpoken && isSpeakerOn) {
  hasSpoken = true;
  speak(streamedText);
}

      setState(() {
        isTyping = false;
      });
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "Error: $e"});
        isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> simulateTyping(
      String text,
      Function(String) onUpdate,
      ) async {
    final words = text.split(" ");
    String temp = "";

    for (int i = 0; i < words.length; i++) {
      temp += (i == 0 ? "" : " ") + words[i];
      onUpdate(temp);
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.stop();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Airi AI"),
  centerTitle: true,
  actions: [
    IconButton(
      icon: Icon(
        isSpeakerOn ? Icons.volume_up : Icons.volume_off,
      ),
      onPressed: () async {
        setState(() {
          isSpeakerOn = !isSpeakerOn;
        });

        if (!isSpeakerOn) {
          await flutterTts.stop();
        }
      },
    )
  ],
),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return const TypingBubble();
                }

                final msg = messages[index];

                return ChatBubble(
                  text: msg["text"]!,
                  isUser: msg["role"] == "user",
                );
              },
            ),
          ),
          InputBox(onSend: sendMessage),
        ],
      ),
    );
  }
}