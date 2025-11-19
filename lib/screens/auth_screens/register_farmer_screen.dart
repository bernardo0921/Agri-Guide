// lib/screens/register_farmer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/notifiers/app_notifiers.dart';
import '../../core/language/app_strings.dart';

class FarmerRegisterScreen extends StatefulWidget {
  const FarmerRegisterScreen({super.key});

  @override
  State<FarmerRegisterScreen> createState() => _FarmerRegisterScreenState();
}

class _FarmerRegisterScreenState extends State<FarmerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Using a map to hold all form data
  final Map<String, String> _formData = {
    'username': '',
    'email': '',
    'password': '',
    'password_confirm': '',
    'first_name': '',
    'last_name': '',
    'phone_number': '',
    'farm_name': '',
    'farm_size': '',
    'location': '',
    'region': '',
    'crops_grown': '',
    'farming_method': 'conventional', // Default value
    'years_of_experience': '',
  };

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
      'farmer_profile': {
        'farm_name': _formData['farm_name'],
        'farm_size': double.tryParse(_formData['farm_size'] ?? '0'),
        'location': _formData['location'],
        'region': _formData['region'],
        'crops_grown': _formData['crops_grown'],
        'farming_method': _formData['farming_method'],
        'years_of_experience': int.tryParse(
          _formData['years_of_experience'] ?? '0',
        ),
      },
    };

    try {
      await Provider.of<AuthService>(
        context,
        listen: false,
      ).registerFarmer(registrationData);
      // If successful, the AuthWrapper will navigate to Home
      // But we are in a sub-page, so pop back to the login screen
      // which will then be rebuilt by AuthWrapper
      if (mounted) {
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
            return Text(AppStrings.registerAsFarmer);
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
                children: [
                  Text(
                    AppStrings.createFarmerAccount,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // --- Account Fields ---
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
                  const SizedBox(height: 16),
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

                  // --- Farmer Profile Fields ---
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.farmDetails,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    'farm_name',
                    AppStrings.farmName,
                    Icons.home_work,
                  ),
                  _buildTextFormField(
                    'farm_size',
                    AppStrings.farmSize,
                    Icons.landscape,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextFormField(
                    'location',
                    AppStrings.location,
                    Icons.location_on,
                  ),
                  _buildTextFormField(
                    'region',
                    AppStrings.region,
                    Icons.map,
                  ),
                  _buildTextFormField(
                    'crops_grown',
                    AppStrings.cropsGrown,
                    Icons.eco,
                  ),
                  _buildTextFormField(
                    'years_of_experience',
                    AppStrings.yearsOfExperience,
                    Icons.history,
                    keyboardType: TextInputType.number,
                  ),

                  // Farming Method Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _formData['farming_method'],
                    decoration: InputDecoration(
                      labelText: AppStrings.farmingMethod,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.agriculture),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'conventional',
                        child: Text(AppStrings.conventional),
                      ),
                      DropdownMenuItem(
                        value: 'organic',
                        child: Text(AppStrings.organic),
                      ),
                      DropdownMenuItem(
                        value: 'mixed',
                        child: Text(AppStrings.mixed),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _formData['farming_method'] = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
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
            // Make some fields optional if needed, based on your model
            if (key == 'farm_name' || key == 'farm_size' || key == 'location') {
              return null; // These can be blank
            }
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