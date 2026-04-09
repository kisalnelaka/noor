import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final token = await authService.getToken();
  
  runApp(AuraApp(initialScreen: token != null ? const MainLayout() : const LoginScreen()));
}

class AuraApp extends StatelessWidget {
  final Widget initialScreen;
  
  const AuraApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOOR',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.lightTheme,
      home: initialScreen,
    );
  }
}
