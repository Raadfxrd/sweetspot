import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/room_design/screens/room_design_screen.dart';

class SweetspotApp extends StatelessWidget {
  const SweetspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweetspot',
      theme: AppTheme.dark(),
      home: const RoomDesignScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
