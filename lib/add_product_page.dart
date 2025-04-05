import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

// ✅ استيراد مساعد الملفات لتشغيل الصور عبر الويب والموبايل
import 'file_helper.dart' if (dart.library.io) 'file_helper_io.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _selectedCategory;

  // ✅ قائمة التصنيفات المتاحة
final List<String> _categories = ["jeans", "tshirt", "vest", "accessoire", "shoes", "all"];

  // ✅ اختيار الصورة من المعرض
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) {
      print("❌ لم يتم تحديد صورة");
      return;
    }

    if (kIsWeb) {
      Uint8List? webImageBytes = await pickedFile.readAsBytes();
      if (webImageBytes == null) {
        print("❌ فشل في قراءة بيانات الصورة (Web)");
        return;
      }
      setState(() {
        _pickedFile = pickedFile;
        _imageBytes = webImageBytes;
      });
    } else {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  // ✅ تحميل الصورة إلى Firebase Storage وحفظ بيانات المنتج
  Future<void> _uploadImage() async {
    print("📤 جاري رفع المنتج...");

    if (_pickedFile == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ يرجى اختيار صورة وتصنيف للمنتج!")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ تحديد مجلد التصنيف لحفظ الصور داخله
      String fileName = "product_images/$_selectedCategory/${Uuid().v4()}";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        if (_imageBytes == null) {
          setState(() => _isUploading = false);
          return;
        }
        uploadTask = ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: "image/jpeg"),
        );
      } else {
        var selectedFile = getFile(_pickedFile!);
        if (selectedFile == null) {
          setState(() => _isUploading = false);
          return;
        }
        uploadTask = ref.putFile(
          selectedFile,
          SettableMetadata(contentType: "image/jpeg"),
        );
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("✅ تم رفع الصورة بنجاح: $downloadUrl");

      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

      // ✅ حفظ بيانات المنتج في Firestore
      await FirebaseFirestore.instance.collection("products").add({
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "imageUrl": downloadUrl,
        "category": _selectedCategory!,
        "sellerPhone": _phoneController.text.trim(),
        "userId": userId,
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ تم حفظ المنتج في Firestore");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم رفع المنتج بنجاح!")),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, downloadUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل الرفع: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة منتج"), backgroundColor: Colors.deepOrange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: _pickedFile == null
                        ? const Center(child: Text("📷 اختر صورة"))
                        : kIsWeb
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : Image.file(getFile(_pickedFile!)!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(_nameController, "اسم المنتج", Icons.shopping_bag),
                const SizedBox(height: 10),
                _buildTextField(_descriptionController, "الوصف", Icons.description),
                const SizedBox(height: 10),
                _buildTextField(_priceController, "السعر", Icons.attach_money, isNumeric: true),
                const SizedBox(height: 10),
                _buildTextField(_phoneController, "رقم الهاتف", Icons.phone, isNumeric: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: "الفئة",
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadImage,
                        icon: const Icon(Icons.add),
                        label: const Text("إضافة المنتج"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return "يرجى إدخال $label";
        if (isNumeric && double.tryParse(value) == null) return "أدخل رقمًا صحيحًا";
        return null;
      },
    );
  }
}
