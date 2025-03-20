import 'dart:io';
import 'package:image_picker/image_picker.dart';

File? getFile(XFile file) {
  if (file.path.isEmpty) {
    print("❌ Error: File path is empty (Mobile)");
    return null;
  }
  return File(file.path);
}
