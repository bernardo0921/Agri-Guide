// lib/screens/auth_screens/register_farmer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/notifiers/app_notifiers.dart';
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

  final Map<String, dynamic> _formData = {
    'username': '',
    'email': '',
    'password': '',
    'password_confirm': '',
    'first_name': '',
    'last_name': '',
    'phone_number': '',
    'user_type': 'farmer',
    'farm_name': '',
    'farm_size': '',
    'location': '',
    'region': '',
    'crops_grown': '', // String initially
    'farming_method': 'conventional',
    'years_of_experience': '',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_formData['password'] != _formData['password_confirm']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.passwordsDoNotMatch), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Process Data
      final cropsList = (_formData['crops_grown'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final registrationData = {
        ..._formData,
        'crops_grown': cropsList,
        'years_of_experience': int.tryParse(_formData['years_of_experience'].toString()) ?? 0,
      };

      // Step 1: Request Code
      await authService.requestRegistrationCode(registrationData);

      if (!mounted) return;

      // Step 2: Navigate to Verify
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => VerificationCodeScreen(
            email: _formData['email'],
            purpose: 'registration',
            onVerify: (code) async {
              // The backend might need full data OR cached data. 
              // Assuming 'verifyAndRegister' needs generic data or just email/code.
              // If backend fails saying "missing fields", we must pass 'registrationData' here.
              // Based on AuthService, it sends email + code.
              await authService.verifyAndRegister(_formData['email'], code);
              
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Welcome, Farmer!'), backgroundColor: Colors.green),
                );
              }
            },
            onResend: () async {
              await authService.resendVerificationCode(_formData['email'], 'registration');
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
      appBar: AppBar(title: Text(AppStrings.registerAsFarmer)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField('username', AppStrings.username, Icons.person),
              _buildTextFormField('email', AppStrings.email, Icons.email, keyboardType: TextInputType.emailAddress),
              _buildTextFormField('password', AppStrings.password, Icons.lock, obscureText: true),
              _buildTextFormField('password_confirm', AppStrings.confirmPassword, Icons.lock_outline, obscureText: true),
              _buildTextFormField('first_name', AppStrings.firstName, Icons.badge),
              _buildTextFormField('last_name', AppStrings.lastName, Icons.badge),
              _buildTextFormField('phone_number', AppStrings.phoneNumber, Icons.phone, keyboardType: TextInputType.phone),
              _buildTextFormField('farm_name', AppStrings.farmName, Icons.home_work),
              _buildTextFormField('location', AppStrings.location, Icons.location_on),
              _buildTextFormField('crops_grown', 'Crops (comma separated)', Icons.eco),
              
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(AppStrings.register),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String key, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) => (value == null || value.isEmpty) ? AppStrings.fieldRequired : null,
        onSaved: (value) => _formData[key] = value ?? '',
      ),
    );
  }
}