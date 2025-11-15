// lib/screens/register_farmer_screen.dart
import 'package:agri_guide/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(title: const Text('Register as Farmer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Create Farmer Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // --- Account Fields ---
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
              const SizedBox(height: 16),
              _buildTextFormField('first_name', 'First Name', Icons.badge),
              _buildTextFormField('last_name', 'Last Name', Icons.badge),
              _buildTextFormField(
                'phone_number',
                'Phone Number (e.g., +233...)',
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),

              // --- Farmer Profile Fields ---
              const SizedBox(height: 16),
              Text(
                'Farm Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              _buildTextFormField('farm_name', 'Farm Name', Icons.home_work),
              _buildTextFormField(
                'farm_size',
                'Farm Size (in acres)',
                Icons.landscape,
                keyboardType: TextInputType.number,
              ),
              _buildTextFormField(
                'location',
                'Location (e.g., Town/Village)',
                Icons.location_on,
              ),
              _buildTextFormField('region', 'Region', Icons.map),
              _buildTextFormField(
                'crops_grown',
                'Crops Grown (comma-separated)',
                Icons.eco,
              ),
              _buildTextFormField(
                'years_of_experience',
                'Years of Experience',
                Icons.history,
                keyboardType: TextInputType.number,
              ),

              // Farming Method Dropdown
              DropdownButtonFormField<String>(
                initialValue: _formData['farming_method'],
                decoration: const InputDecoration(
                  labelText: 'Farming Method',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                items: ['conventional', 'organic', 'mixed']
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(
                          method[0].toUpperCase() + method.substring(1),
                        ),
                      ),
                    )
                    .toList(),
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
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to reduce boilerplate
  // --- FIXED ---
  // Changed the optional parameters to be NAMED parameters ({})
  // This avoids the error and is easier to read.
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
            // Make some fields optional if needed, based on your model
            if (key == 'farm_name' || key == 'farm_size' || key == 'location') {
              return null; // These can be blank
            }
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
