import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/session/session_manager.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check active user session
  final isLoggedIn = await SessionManager.instance.isLoggedIn();
  final themeMode = await SessionManager.instance.getThemeMode();

  runApp(SmartAgroApp(
    isLoggedIn: isLoggedIn,
    initialThemeMode: themeMode,
  ));
}

class SmartAgroApp extends StatefulWidget {
  final bool isLoggedIn;
  final String initialThemeMode;

  const SmartAgroApp({
    super.key,
    required this.isLoggedIn,
    required this.initialThemeMode,
  });

  @override
  State<SmartAgroApp> createState() => _SmartAgroAppState();
}

class _SmartAgroAppState extends State<SmartAgroApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode == 'dark'
        ? ThemeMode.dark
        : widget.initialThemeMode == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        SessionManager.instance.setThemeMode('dark');
      } else {
        _themeMode = ThemeMode.light;
        SessionManager.instance.setThemeMode('light');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Agro System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: widget.isLoggedIn
          ? MainNavigationShell(onThemeToggle: _toggleTheme)
          : const LoginScreen(),
    );
  }
}
