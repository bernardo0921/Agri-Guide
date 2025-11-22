// lib/utils/file_picker_utility.dart
import 'package:file_picker/file_picker.dart';

/// Opens the file picker and allows selection of image files.
/// Returns the file path of the selected image, or null if cancelled.
Future<String?> pickImageFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      // Return the path of the selected file
      return result.files.single.path;
    } else {
      // User canceled the picker
      return null;
    }
  } catch (e) {
    // Handle error during file picking
    // print('Error picking image file: $e');
    return null;
  }
}