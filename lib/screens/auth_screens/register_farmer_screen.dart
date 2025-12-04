// lib/screens/auth_screens/register_farmer_screen.dart - SIMPLIFIED
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/language/app_strings.dart';
import 'verification_code_screen.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() => _FarmerRegisterScreenState();
}

class _FarmerRegisterScreenState extends State<FarmerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ✅ SIMPLIFIED - Only basic user fields
  final Map<String, dynamic> _formData = {
    'username': '',
    'email': '',
    'password': '',
    'password_confirm': '',
    'first_name': '',
    'last_name': '',
    'phone_number': '',
    'user_type': 'farmer',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_formData['password'] != _formData['password_confirm']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.passwordsDoNotMatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Step 1: Request Code
      await authService.requestRegistrationCode(_formData);

      if (!mounted) return;

      // Step 2: Navigate to Verify
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => VerificationCodeScreen(
            email: _formData['email'],
            purpose: 'registration',
            onVerify: (code) async {
              await authService.verifyAndRegister(_formData['email'], code);
              
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Welcome, Farmer! 🌾'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            onResend: () async {
              await authService.resendVerificationCode(
                _formData['email'],
                'registration',
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.registerAsFarmer)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header Icon
              Icon(
                Icons.agriculture,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Create Farmer Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the AgriGuide community',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Basic Fields Only
              _buildTextFormField(
                'username',
                AppStrings.username,
                Icons.person,
              ),
              _buildTextFormField(
                'email',
                AppStrings.email,
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                'password',
                AppStrings.password,
                Icons.lock,
                obscureText: true,
              ),
              _buildTextFormField(
                'password_confirm',
                AppStrings.confirmPassword,
                Icons.lock_outline,
                obscureText: true,
              ),
              
              const Divider(height: 30),
              
              _buildTextFormField(
                'first_name',
                AppStrings.firstName,
                Icons.badge,
              ),
              _buildTextFormField(
                'last_name',
                AppStrings.lastName,
                Icons.badge,
              ),
              _buildTextFormField(
                'phone_number',
                AppStrings.phoneNumber,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 30),
              
              // Submit Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppStrings.register,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
              
              const SizedBox(height: 16),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive a verification code via email',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    String key,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) =>
            (value == null || value.isEmpty) ? AppStrings.fieldRequired : null,
        onSaved: (value) => _formData[key] = value ?? '',
      ),
    );
  }
}