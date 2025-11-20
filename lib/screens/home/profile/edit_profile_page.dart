// lib/screens/home/Navigation_pages/pages/edit_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late bool isFarmer;

  // Base User Fields
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;

  // Farmer Profile Fields
  late TextEditingController farmNameController;
  late TextEditingController farmSizeController;
  late TextEditingController locationController;
  late TextEditingController regionController;
  late TextEditingController cropsGrownController;
  late TextEditingController farmingMethodController;
  late TextEditingController yearsOfExperienceController;

  bool _isSaving = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    isFarmer = widget.initialData['user_type'] == 'farmer';

    firstNameController = TextEditingController(
      text: widget.initialData['first_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: widget.initialData['last_name'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.initialData['email'] ?? '',
    );
    phoneNumberController = TextEditingController(
      text: widget.initialData['phone_number'] ?? '',
    );

    if (isFarmer) {
      final farmerProfile = widget.initialData['farmer_profile'] ?? {};
      farmNameController = TextEditingController(
        text: farmerProfile['farm_name'] ?? '',
      );
      farmSizeController = TextEditingController(
        text: (farmerProfile['farm_size']?.toString() ?? ''),
      );
      locationController = TextEditingController(
        text: farmerProfile['location'] ?? '',
      );
      regionController = TextEditingController(
        text: farmerProfile['region'] ?? '',
      );
      cropsGrownController = TextEditingController(
        text: farmerProfile['crops_grown'] ?? '',
      );
      farmingMethodController = TextEditingController(
        text: farmerProfile['farming_method'] ?? '',
      );
      yearsOfExperienceController = TextEditingController(
        text: (farmerProfile['years_of_experience']?.toString() ?? ''),
      );
    }

    AppNotifiers.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    if (isFarmer) {
      farmNameController.dispose();
      farmSizeController.dispose();
      locationController.dispose();
      regionController.dispose();
      cropsGrownController.dispose();
      farmingMethodController.dispose();
      yearsOfExperienceController.dispose();
    }
    AppNotifiers.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failedToPickImage}: ${e.toString()}')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: colorScheme.primary),
                title: Text(AppStrings.chooseFromGallery),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colorScheme.primary),
                title: Text(AppStrings.takePhoto),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null ||
                  widget.initialData['profile_picture'] != null)
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(AppStrings.removePhoto),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final Map<String, dynamic> updateData = {
        'first_name': firstNameController.text,
        'last_name': lastNameController.text,
        'email': emailController.text,
        'phone_number': phoneNumberController.text,
      };

      if (isFarmer) {
        updateData['farmer_profile'] = {
          'farm_name': farmNameController.text,
          'farm_size': farmSizeController.text.isNotEmpty
              ? double.tryParse(farmSizeController.text)
              : null,
          'location': locationController.text,
          'region': regionController.text,
          'crops_grown': cropsGrownController.text,
          'farming_method': farmingMethodController.text,
          'years_of_experience': yearsOfExperienceController.text.isNotEmpty
              ? int.tryParse(yearsOfExperienceController.text)
              : null,
        };
      }

      await authService.updateProfile(
        updateData,
        profilePicture: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.profileUpdatedSuccessfully)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.failedToUpdateProfile}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getInitials() {
    final firstName = firstNameController.text;
    final lastName = lastNameController.text;
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder(
      valueListenable: AppNotifiers.languageNotifier,
      builder: (context, language, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.editProfile,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: colorScheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Profile Picture Section
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (widget.initialData['profile_picture'] != null &&
                                      widget.initialData['profile_picture']
                                          .toString()
                                          .isNotEmpty
                                  ? NetworkImage(
                                      widget.initialData['profile_picture'],
                                    )
                                  : null),
                        child:
                            (_selectedImage == null &&
                                (widget.initialData['profile_picture'] == null ||
                                    widget.initialData['profile_picture']
                                        .toString()
                                        .isEmpty))
                            ? Text(
                                _getInitials(),
                                style: TextStyle(
                                  fontSize: 48,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.tapCameraToChangePhoto,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 30),

                  Text(
                    AppStrings.personalInformationTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(color: colorScheme.primary),
                  _buildTextField(firstNameController, AppStrings.firstName, Icons.person),
                  _buildTextField(
                    lastNameController,
                    AppStrings.lastName,
                    Icons.person_outline,
                  ),
                  _buildTextField(
                    emailController,
                    AppStrings.email,
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    isReadOnly: true,
                  ),
                  _buildTextField(
                    phoneNumberController,
                    AppStrings.phoneNumber,
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 30),

                  if (isFarmer) ..._buildFarmerFields(),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isSaving ? AppStrings.saving : AppStrings.saveChanges,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isReadOnly = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodyMedium,
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: isReadOnly,
          fillColor: isReadOnly 
              ? (isDarkMode 
                  ? colorScheme.surface.withOpacity(0.5)
                  : colorScheme.outline.withOpacity(0.1))
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppStrings.fieldIsRequired(label);
          }
          return null;
        },
      ),
    );
  }

  List<Widget> _buildFarmerFields() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      const SizedBox(height: 10),
      Text(
        AppStrings.farmingProfile,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      Divider(color: colorScheme.primary),
      _buildTextField(farmNameController, AppStrings.farmName, Icons.agriculture),
      _buildTextField(
        farmSizeController,
        AppStrings.farmSizeAcres,
        Icons.fence,
        keyboardType: TextInputType.number,
      ),
      _buildTextField(
        locationController,
        AppStrings.specificLocation,
        Icons.location_on,
      ),
      _buildTextField(regionController, AppStrings.region, Icons.map),
      _buildTextField(cropsGrownController, AppStrings.cropsGrownLabel, Icons.grain),
      _buildTextField(farmingMethodController, AppStrings.farmingMethod, Icons.eco),
      _buildTextField(
        yearsOfExperienceController,
        AppStrings.yearsOfExperience,
        Icons.trending_up,
        keyboardType: TextInputType.number,
      ),
    ];
  }
}