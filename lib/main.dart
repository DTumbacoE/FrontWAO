import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Web/LoginWeb.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    // Elimina solo los datos de autenticación y perfil antiguos de WAO.
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

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
