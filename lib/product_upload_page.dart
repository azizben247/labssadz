import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductUploadPage extends StatefulWidget {
  @override
  _ProductUploadPageState createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageList = [];
  List<Uint8List> _webImages = []; // قائمة للصور على الويب
  bool _isUploading = false; // حالة التحميل

  /// ✅ اختيار الصور
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

  /// ✅ رفع الصور إلى Firebase Storage
  Future<void> _uploadImages() async {
    if (_imageList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ الرجاء تحديد صورة لرفعها"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedUrls = [];

      for (int i = 0; i < _imageList.length; i++) {
        String fileName = "product_images/${DateTime.now().millisecondsSinceEpoch}_${i}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask;

        if (kIsWeb) {
          uploadTask = ref.putData(_webImages[i], SettableMetadata(contentType: 'image/jpeg'));
        } else {
          uploadTask = ref.putFile(File(_imageList[i].path));
        }

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      // ✅ حفظ الصور في Firestore
      await FirebaseFirestore.instance.collection('products').add({
        "images": uploadedUrls,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم رفع الصور بنجاح"), backgroundColor: Colors.green),
      );

      // ✅ مسح القائمة بعد التحميل
      setState(() {
        _imageList.clear();
        _webImages.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء الرفع: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  /// ✅ حذف صورة من القائمة
  void _removeImage(int index) {
    setState(() {
      _imageList.removeAt(index);
      if (kIsWeb) {
        _webImages.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("رفع الصور وإدارة المنتجات"),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ✅ زر رفع الصور
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text("اختيار صورة"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
          ),

          const SizedBox(height: 10),

          // ✅ عرض الصور المضافة
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عدد الأعمدة في الشبكة
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _imageList.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    kIsWeb
                        ? Image.memory(_webImages[index], fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(_imageList[index].path), fit: BoxFit.cover, width: double.infinity),

                    // ✅ زر حذف الصورة
                    Positioned(
                      top: 5,
                      right: 5,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 15,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 15),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ✅ زر رفع الصور إلى Firebase
          _isUploading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _uploadImages,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text("رفع الصور"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
