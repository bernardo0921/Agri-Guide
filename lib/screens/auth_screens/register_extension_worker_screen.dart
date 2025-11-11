// lib/screens/auth_screens/register_extension_worker_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';

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
            content: Text('Error picking file: $e'),
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
        const SnackBar(
          content: Text("Passwords do not match."),
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
          const SnackBar(
            content: Text(
              'Registration successful! Your account is pending approval.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
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
      appBar: AppBar(title: const Text('Register as Extension Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Extension Worker Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your account will be reviewed and approved by an administrator',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.orange[700]),
              ),
              const SizedBox(height: 24),

              // --- Account Fields ---
              Text(
                'Account Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTextFormField('username', 'Username', Icons.person),
              _buildTextFormField(
                'email',
                'Email',
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                'password',
                'Password',
                Icons.lock,
                obscureText: true,
              ),
              _buildTextFormField(
                'password_confirm',
                'Confirm Password',
                Icons.lock_outline,
                obscureText: true,
              ),

              // --- Personal Fields ---
              const SizedBox(height: 24),
              Text(
                'Personal Information',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTextFormField('first_name', 'First Name', Icons.badge),
              _buildTextFormField('last_name', 'Last Name', Icons.badge),
              _buildTextFormField(
                'phone_number',
                'Phone Number (e.g., +233...)',
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              // --- Extension Worker Profile Fields ---
              const SizedBox(height: 24),
              Text(
                'Professional Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildTextFormField(
                'organization',
                'Organization/Institution',
                Icons.business,
              ),
              _buildTextFormField(
                'employee_id',
                'Employee ID',
                Icons.badge_outlined,
              ),
              _buildTextFormField(
                'specialization',
                'Specialization (e.g., Crop Science)',
                Icons.science,
              ),
              _buildTextFormField(
                'regions_covered',
                'Regions Covered (comma-separated)',
                Icons.map,
              ),

              // --- Verification Document ---
              const SizedBox(height: 24),
              Text(
                'Verification Document',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload an official document (ID, certificate, or employment letter)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
                  label: const Text('Upload Document'),
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
                      child: const Text('Register'),
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
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (value) {
          if (key == 'email') {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'Please enter a valid email';
            }
          }
          if (value == null || value.isEmpty) {
            return 'This field is required';
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
