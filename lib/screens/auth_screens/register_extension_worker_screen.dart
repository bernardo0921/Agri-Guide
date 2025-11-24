// lib/screens/auth_screens/register_extension_worker_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../core/notifiers/app_notifiers.dart';
import '../../core/language/app_strings.dart';
import 'verification_code_screen.dart';

class ExtensionWorkerRegisterScreen extends StatefulWidget {
  const ExtensionWorkerRegisterScreen({super.key});

  @override
  State<ExtensionWorkerRegisterScreen> createState() =>
      _ExtensionWorkerRegisterScreenState();
}

class _ExtensionWorkerRegisterScreenState
    extends State<ExtensionWorkerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _verificationDocument;
  final _imagePicker = ImagePicker();

  final Map<String, String> _formData = {
    'username': '',
    'email': '',
    'password': '',
    'password_confirm': '',
    'first_name': '',
    'last_name': '',
    'phone_number': '',
    'organization': '',
    'employee_id': '',
    'specialization': '',
    'regions_covered': '',
  };

  Future<void> _pickVerificationDocument() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) {
        setState(() => _verificationDocument = File(file.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

    // ✅ Convert regions_covered string to list
    final regionsList =
        (_formData['regions_covered'] as String?)
            ?.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    final Map<String, dynamic> registrationData = {
      'username': _formData['username'],
      'email': _formData['email'],
      'password': _formData['password'],
      'password_confirm': _formData['password_confirm'],
      'first_name': _formData['first_name'],
      'last_name': _formData['last_name'],
      'phone_number': _formData['phone_number'],
      'user_type': 'extension_worker',
      'organization': _formData['organization'],
      'employee_id': _formData['employee_id'],
      'specialization': _formData['specialization'],
      'regions_covered': regionsList, // ✅ Send as list
    };

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Step 1: Request Code
      await authService.initiateExtensionWorkerRegistration(registrationData);

      if (!mounted) return;

      // Step 2: Navigate to Verification
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => VerificationCodeScreen(
            email: _formData['email']!,
            purpose: 'registration',
            onVerify: (code) async {
              // Step 3: Complete Registration (Upload + Code)
              await authService.completeExtensionWorkerRegistration(
                registrationData: registrationData,
                verificationCode: code,
                verificationDocument: _verificationDocument,
              );

              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration Successful!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            onResend: () async {
              await authService.resendVerificationCode(
                _formData['email']!,
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
      appBar: AppBar(title: Text(AppStrings.registerAsExtensionWorker)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const Divider(height: 30),
              _buildTextFormField(
                'organization',
                AppStrings.organization,
                Icons.business,
              ),
              _buildTextFormField(
                'employee_id',
                AppStrings.employeeId,
                Icons.badge_outlined,
              ),
              _buildTextFormField(
                'specialization',
                AppStrings.specialization,
                Icons.science,
              ),
              _buildTextFormField(
                'regions_covered',
                AppStrings.regionsCovered,
                Icons.map,
              ),
              const SizedBox(height: 20),

              // Document Upload UI
              if (_verificationDocument != null)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(_verificationDocument!.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        setState(() => _verificationDocument = null),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickVerificationDocument,
                  icon: const Icon(Icons.upload_file),
                  label: Text(AppStrings.uploadDocument),
                ),

              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(AppStrings.register),
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
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) =>
            (value == null || value.isEmpty) ? AppStrings.fieldRequired : null,
        onSaved: (value) => _formData[key] = value?.trim() ?? '',
      ),
    );
  }
}
