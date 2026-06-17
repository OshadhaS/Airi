import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class InputBox extends StatefulWidget {
  final Function(String) onSend;

  const InputBox({super.key, required this.onSend});

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  final TextEditingController controller = TextEditingController();
  late stt.SpeechToText speech;

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  void send() {
    if (controller.text.trim().isEmpty) return;

    widget.onSend(controller.text);
    controller.clear();

    // 🛑 auto stop mic after send
    if (isListening) {
      speech.stop();
      setState(() => isListening = false);
    }
  }

  void toggleMic() async {
  print("Mic button pressed");

  if (!isListening) {

    bool available = await speech.initialize(
      onStatus: (status) {
        print("Status: $status");

        if (status == "done" || status == "notListening") {
          setState(() => isListening = false);
        }
      },
      onError: (error) {
        print("Speech Error: $error");
      },
    );

    print("Speech available: $available");

    if (available) {
      setState(() => isListening = true);

      speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        onResult: (result) {
          print("Recognized: ${result.recognizedWords}");

          setState(() {
            controller.text = result.recognizedWords;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          });
        },
      );
    } else {
      print("Speech recognition not available.");
    }
  } else {
    setState(() => isListening = false);
    speech.stop();
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isListening ? "🎤 Listening..." : "Type message...",
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.red : null,
            ),
            onPressed: toggleMic,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: send,
          ),
        ],
      ),
    );
  }
}