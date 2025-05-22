import 'package:flutter/material.dart';
import 'package:llama_bot/screens/bot_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Traffic Bot',
      home: TrafficBotPage(),
    );
  }
}
