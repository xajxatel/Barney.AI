import 'package:barney/consts.dart';
import 'package:barney/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

void main() {
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'barney.ai',
      theme: ThemeData(
        
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
