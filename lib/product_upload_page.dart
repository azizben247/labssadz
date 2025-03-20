import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductUploadPage extends StatefulWidget {
  @override
  _ProductUploadPageState createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageList = [];
  List<Uint8List> _webImages = []; // Store web image data

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageList.add(pickedFile);
      });

      if (kIsWeb) {
        _webImages.add(await pickedFile.readAsBytes());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("رفع الصور وعرض المنتجات"),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text("رفع صورة"),
          ),
          SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عدد الأعمدة في الشبكة
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _imageList.length,
              itemBuilder: (context, index) {
                return kIsWeb
                    ? Image.memory(_webImages[index], fit: BoxFit.cover)
                    : Image.file(File(_imageList[index].path),
                        fit: BoxFit.cover);
              },
            ),
          ),
        ],
      ),
    );
  }
}
