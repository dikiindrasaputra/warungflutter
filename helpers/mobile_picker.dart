// lib/helpers/mobile_picker.dart

import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// Picks an image from the gallery on mobile.
Future<dynamic> pickImage() async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile;
  } catch (e) {
    print('Error picking image: $e');
    return null;
  }
}