
import 'package:flutter/material.dart';
import 'Web/LoginWeb.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaoWebApp());
}

class WaoWebApp extends StatelessWidget {
  const WaoWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAO - Descubre, Vive y Planifica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
        ),
      ),
      home: const LoginWeb(),
    );
  }
}
