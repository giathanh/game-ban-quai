import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/main_menu/presentation/screens/main_menu_screen.dart';

class BanHeoApp extends StatelessWidget {
  const BanHeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bắn Heo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainMenuScreen(),
    );
  }
}
