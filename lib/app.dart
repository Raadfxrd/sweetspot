import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/room_design/screens/room_design_screen.dart';
import 'features/splash/splash_screen.dart';

class SweetspotApp extends StatefulWidget {
  const SweetspotApp({super.key});

  @override
  State<SweetspotApp> createState() => _SweetspotAppState();
}

class _SweetspotAppState extends State<SweetspotApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweetspot',
      theme: AppTheme.dark(),
      home: AnimatedSwitcher(
        duration: AppTheme.motionMedium,
        switchInCurve: AppTheme.easeStandard,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _showSplash
            ? SplashScreen(
                key: const ValueKey('splash_screen'),
                onComplete: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              )
            : const RoomDesignScreen(key: ValueKey('room_design_screen')),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
