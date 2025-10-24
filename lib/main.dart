import 'package:flutter/material.dart';
import 'services/gemini_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final gemini = GeminiService();
  String response = 'Waiting...';

  @override
  void initState() {
    super.initState();
    _getGeminiResponse();
  }

  Future<void> _getGeminiResponse() async {
    try {
      final res = await gemini.generateResponse('Hello Gemini!');
      setState(() => response = res);
    } catch (e) {
      setState(() => response = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Gemini Test')),
        body: Center(child: Text(response)),
      ),
    );
  }
}
