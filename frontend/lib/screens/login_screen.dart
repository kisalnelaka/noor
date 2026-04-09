import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (result['success']) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } else {
      setState(() { 
        _isLoading = false; 
        _errorMessage = result['message']; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraTheme.background,
      body: Stack(
        children: [
          // 🪐 Cosmic Background
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuraTheme.accentBlue.withOpacity(0.15),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text('N O O R', style: TextStyle(
                    fontSize: 42, color: AuraTheme.textPrimary, letterSpacing: 12, fontWeight: FontWeight.w200
                  )),
                  const SizedBox(height: 8),
                  Text('IQ REAL ESTATE INTELLIGENCE', style: TextStyle(
                    fontSize: 10, color: AuraTheme.textSecondary, letterSpacing: 4
                  )),
                  const SizedBox(height: 60),
                  
                  _buildGlassCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: AuraTheme.solidDecoration(radius: 24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('EMAIL', _emailController, false),
              const SizedBox(height: 20),
              _buildTextField('PASSWORD', _passwordController, true),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              
              const SizedBox(height: 32),
              
              _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AuraTheme.accentBlue))
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuraTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: AuraTheme.accentBlue.withOpacity(0.5),
                    ),
                    child: const Text('LOGIN', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ),
                  
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New to NOOR?", style: TextStyle(color: AuraTheme.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text("Create Account", style: TextStyle(color: AuraTheme.accentBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AuraTheme.textSecondary, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: AuraTheme.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: AuraTheme.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuraTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AuraTheme.accentBlue, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
