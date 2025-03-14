import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// ✅ Web does not support `File`, so we return `null`
Uint8List? getFileBytes(XFile? file) {
  return null; // Web only uses bytes
}

// ✅ Provide a dummy function for Web to prevent errors
dynamic getFile(XFile file) {
  return null;
}
