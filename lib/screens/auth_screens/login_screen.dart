// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/notifiers/app_notifiers.dart';
import '../../core/language/app_strings.dart';
import 'role_selection_screen.dart';
import 'verification_code_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Step 1: Request Code
      await authService.requestLoginCode(email);

      if (!mounted) return;

      // Step 2: Navigate to Verification
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => VerificationCodeScreen(
            email: email,
            purpose: 'login',
            onVerify: (code) async {
              // Step 3: Verify & Login
              await authService.verifyAndLogin(email, code, password);

              if (mounted) {
                Navigator.of(context).pop(); // Pop verification
                // Navigation to Home is handled by AuthWrapper listening to user state
              }
            },
            onResend: () async {
              await authService.resendVerificationCode(email, 'login');
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 80, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text(AppStrings.welcomeTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                    validator: (v) => (v!.isEmpty || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Password required' : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
                          child: Text(AppStrings.login),
                        ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoleSelectionScreen())),
                    child: Text(AppStrings.createAccount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}