// lib/helpers/web_picker.dart

import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';

/// Picks an image from the gallery on web.
Future<dynamic> pickImage() async {
  try {
    return await ImagePickerWeb.getImageAsBytes();
  } catch (e) {
    print('Error picking image: $e');
    return null;
  }
}