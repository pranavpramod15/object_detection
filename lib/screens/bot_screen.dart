import 'package:flutter/material.dart';
import 'package:llama_bot/core/video_service.dart';
import 'package:provider/provider.dart';
import 'package:llama_bot/widgets/chat_bubble.dart';
import 'package:llama_bot/widgets/typing_indicator.dart';
import 'package:llama_bot/widgets/upload_status_indicator.dart';
import 'package:video_player/video_player.dart';

class TrafficBotPage extends StatelessWidget {
  const TrafficBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrafficBotService(
        baseUrl: 'https://72dc-14-194-29-26.ngrok-free.app',
      ),
      child: const TrafficBotView(),
    );
  }
}

class TrafficBotView extends StatelessWidget {
  const TrafficBotView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrafficBotService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Traffic Chat Bot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: controller.uploadVideo,
            tooltip: "Upload Traffic Video",
          )
        ],
      ),
      body: Column(
        children: [
          if (controller.showUploadInfo)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Upload a video to begin asking questions."),
            ),
          if (controller.uploadStatus != null)
            UploadStatusIndicator(uploadStatus: controller.uploadStatus!),
          if (controller.isVideoReady && controller.videoController != null)
            AspectRatio(
              aspectRatio: controller.videoController!.value.aspectRatio,
              child: VideoPlayer(controller.videoController!),
            ),
          if (controller.result != null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length +
                    (controller.isBotTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < controller.messages.length) {
                    final message = controller.messages[index];
                    return ChatBubble(
                        text: message['text']!, role: message['role']!);
                  } else {
                    return const TypingIndicator();
                  }
                },
              ),
            ),
          if (controller.result != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.inputController,
                      onSubmitted: (_) => controller.sendMessage(),
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
                    onPressed: controller.sendMessage,
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
