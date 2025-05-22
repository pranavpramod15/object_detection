import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:llama_bot/widgets/chat_bubble.dart';
import 'package:llama_bot/widgets/typing_indicator.dart';
import 'package:llama_bot/widgets/upload_status_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Traffic Bot', home: TrafficBotPage());
  }
}

class TrafficBotPage extends StatefulWidget {
  const TrafficBotPage({super.key});

  @override
  State<TrafficBotPage> createState() => _TrafficBotPageState();
}

class _TrafficBotPageState extends State<TrafficBotPage> {
  final String baseUrl = 'https://72dc-14-194-29-26.ngrok-free.app';
  String? _uploadStatus;
  bool _showUploadInfo = true;
  Map<String, dynamic>? result;
  String? taskId;
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;
  bool _isBotTyping = false;
  List<Map<String, String>> messages = []; // [{role:'user'/'bot', text:'...'}]

  final TextEditingController _controller = TextEditingController();

  Future<void> uploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // Dispose old video controller if any
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
      }

      setState(() {
        _uploadStatus = "Uploading...";
        _showUploadInfo = false;
        messages.clear();
        result = null;
        _isVideoReady = false;
      });

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {   
        final body = await response.stream.bytesToString();
        final jsonResp = jsonDecode(body);
        taskId = jsonResp['task_id'];

        setState(() {
          _uploadStatus = "Processing...";
        });

        await pollForResult(taskId!);
      } else {
        _showSnackBar("Upload failed: ${response.statusCode}");
        setState(() {
          _uploadStatus = null;
          _showUploadInfo = true;
        });
      }
    }
  }

 

  Future<void> pollForResult(String taskId) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      final res = await http.get(Uri.parse('$baseUrl/result?task_id=$taskId'));

      if (res.statusCode == 200) {
        final jsonResult = jsonDecode(res.body);

        if (jsonResult['analytics'] != null) {
          setState(() {
            result = jsonResult['analytics'];
            _uploadStatus = "Upload Complete";
          });

          // Init video player
          final videoUrl = '$baseUrl/video/${jsonResult['filename']}';
          _videoController = VideoPlayerController.network(videoUrl)
            ..initialize().then((_) {
              setState(() {
                _isVideoReady = true;
              });
              _videoController?.play(); // auto-play
            });

          _showSnackBar("Video processed. You can now ask questions.");
          break;
        }
      }
    }
  }

  Future<void> sendMessage(String question) async {
    if (question.trim().isEmpty || result == null) return;

    setState(() {
      messages.add({'role': 'user', 'text': question});
      _isBotTyping = true;
      _controller.clear();
    });

    final response = await http.post(
      Uri.parse('$baseUrl/ask/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'result': result}),
    );

    if (response.statusCode == 200) {
      final answer = jsonDecode(response.body)['answer'];
      setState(() {
        messages.add({'role': 'bot', 'text': answer});
      });
    } else {
      _showSnackBar("Bot failed to respond.");
    }

    setState(() {
      _isBotTyping = false;
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Traffic Chat Bot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: uploadVideo,
            tooltip: "Upload Traffic Video",
          )
        ],
      ),
      body: Column(
        children: [
          if (_showUploadInfo)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Upload a video to begin asking questions."),
            ),
          if (_uploadStatus != null)
            UploadStatusIndicator(uploadStatus: _uploadStatus!),
          if (_isVideoReady && _videoController != null)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          if (result != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (_isBotTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    final message = messages[index];
                    return ChatBubble(
                        text: message['text']!, role: message['role']!);
                  } else {
                    return const TypingIndicator();
                  }
                },
              ),
            ),
          if (result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: sendMessage,
                      decoration: InputDecoration(
                        hintText: "Ask a question...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => sendMessage(_controller.text),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
