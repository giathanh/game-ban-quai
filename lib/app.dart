import 'package:flutter/material.dart';

import 'screens/main_menu_screen.dart';

class BanHeoApp extends StatelessWidget {
  const BanHeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bắn Heo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF43A047),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
