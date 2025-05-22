import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class TrafficBotService extends ChangeNotifier {
  final String baseUrl;

  TrafficBotService({required this.baseUrl});

  String? uploadStatus;
  bool showUploadInfo = true;
  Map<String, dynamic>? result;
  String? taskId;
  VideoPlayerController? videoController;
  bool isVideoReady = false;
  bool isBotTyping = false;
  List<Map<String, String>> messages = [];

  final TextEditingController inputController = TextEditingController();

  Future<void> uploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      await videoController?.pause();
      await videoController?.dispose();
      videoController = null;

      uploadStatus = "Uploading...";
      showUploadInfo = false;
      messages.clear();
      result = null;
      isVideoReady = false;
      notifyListeners();

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/'))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonResp = jsonDecode(body);
        taskId = jsonResp['task_id'];

        uploadStatus = "Processing...";
        notifyListeners();

        await processVideo(taskId!);
      } else {
        uploadStatus = null;
        showUploadInfo = true;
        notifyListeners();
      }
    }
  }

  Future<void> processVideo(String taskId) async {       
    while (true) {
      await Future.delayed(const Duration(seconds: 3));
      final res = await http.get(Uri.parse('$baseUrl/result?task_id=$taskId'));

      if (res.statusCode == 200) {
        final jsonResult = jsonDecode(res.body);

        if (jsonResult['analytics'] != null) {
          result = jsonResult['analytics'];
          uploadStatus = "Upload Complete";

          final videoUrl = '$baseUrl/video/${jsonResult['filename']}';
          videoController = VideoPlayerController.network(videoUrl);
          await videoController!.initialize();
          videoController!.play();
          isVideoReady = true;
          notifyListeners();
          break;
        }
      }
    }
  }

  Future<void> sendMessage() async {
    String question = inputController.text.trim();
    if (question.isEmpty || result == null) return;

    messages.add({'role': 'user', 'text': question});
    isBotTyping = true;
    inputController.clear();
    notifyListeners();

    final response = await http.post(
      Uri.parse('$baseUrl/ask/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question, 'result': result}),
    );

    if (response.statusCode == 200) {
      final answer = jsonDecode(response.body)['answer'];
      messages.add({'role': 'bot', 'text': answer});
    }

    isBotTyping = false;
    notifyListeners();
  }
}
