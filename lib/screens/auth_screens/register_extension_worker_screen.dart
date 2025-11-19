// lib/screens/auth_screens/register_extension_worker_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../core/notifiers/app_notifiers.dart';
import '../../core/language/app_strings.dart';

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

  // Using a map to hold all form data
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
        setState(() {
          _verificationDocument = File(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.errorPickingFile}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // Check if passwords match
    if (_formData['password'] != _formData['password_confirm']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.passwordsDoNotMatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Build the nested data structure required by the serializer
    final Map<String, dynamic> registrationData = {
      'username': _formData['username'],
      'email': _formData['email'],
      'password': _formData['password'],
      'password_confirm': _formData['password_confirm'],
      'first_name': _formData['first_name'],
      'last_name': _formData['last_name'],
      'phone_number': _formData['phone_number'],
      'extension_worker_profile': {
        'organization': _formData['organization'],
        'employee_id': _formData['employee_id'],
        'specialization': _formData['specialization'],
        'regions_covered': _formData['regions_covered'],
      },
    };

    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).registerExtensionWorker(
        registrationData,
        verificationDocument: _verificationDocument,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.registrationSuccessful),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: AppNotifiers.languageNotifier,
          builder: (context, language, child) {
            return Text(AppStrings.registerAsExtensionWorker);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ValueListenableBuilder(
          valueListenable: AppNotifiers.languageNotifier,
          builder: (context, language, child) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.createExtensionWorkerAccount,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.accountPendingApproval,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.orange[700]),
                  ),
                  const SizedBox(height: 24),

                  // --- Account Fields ---
                  Text(
                    AppStrings.accountInformation,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
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

                  // --- Personal Fields ---
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.personalInformation,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
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

                  // --- Extension Worker Profile Fields ---
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.professionalDetails,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

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

                  // --- Verification Document ---
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.verificationDocument,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.uploadDocumentDescription,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  if (_verificationDocument != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.insert_drive_file,
                          color: Colors.blue,
                        ),
                        title: Text(
                          _verificationDocument!.path.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _verificationDocument = null;
                            });
                          },
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickVerificationDocument,
                      icon: const Icon(Icons.upload_file),
                      label: Text(AppStrings.uploadDocument),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(AppStrings.register),
                        ),
                ],
              ),
            );
          },
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
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          if (key == 'email') {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return AppStrings.pleaseEnterValidEmail;
            }
          }
          if (value == null || value.isEmpty) {
            return AppStrings.fieldRequired;
          }
          return null;
        },
        onSaved: (value) {
          _formData[key] = value ?? '';
        },
      ),
    );
  }
}