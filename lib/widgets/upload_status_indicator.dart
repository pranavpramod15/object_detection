import 'package:flutter/material.dart';

class UploadStatusIndicator extends StatefulWidget {
  final String uploadStatus;
  const UploadStatusIndicator({super.key, required this.uploadStatus});

  @override
  State<UploadStatusIndicator> createState() => _UploadStatusIndicatorState();
}

class _UploadStatusIndicatorState extends State<UploadStatusIndicator> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.uploadStatus,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
