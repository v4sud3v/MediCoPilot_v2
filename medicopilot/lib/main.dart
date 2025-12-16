import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'pages/pages.dart';

void main() {
  runApp(const MediCoPilotApp());
}

class MediCoPilotApp extends StatefulWidget {
  const MediCoPilotApp({super.key});

  @override
  State<MediCoPilotApp> createState() => _MediCoPilotAppState();
}

class _MediCoPilotAppState extends State<MediCoPilotApp> {
  bool _isLoggedIn = true; // Skip login for now

  void _handleLogin(String email, String password) {
    // TODO: Implement actual authentication
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCoPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoggedIn
          ? AppShell(onLogout: _handleLogout)
          : LoginPage(onLogin: _handleLogin),
    );
  }
}
