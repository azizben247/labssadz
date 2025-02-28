import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _image; // 🔹 ملف الصورة المخزن محليًا
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    String fileName = Uuid().v4(); // 🔹 إنشاء اسم فريد للصورة
    Reference ref = FirebaseStorage.instance.ref().child("product_images/$fileName.jpg");
    UploadTask uploadTask = ref.putFile(image);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL(); // 🔹 الحصول على رابط الصورة
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إدخال جميع البيانات وتحميل صورة"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await _uploadImage(_image!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل تحميل الصورة!"), backgroundColor: Colors.red),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    String productId = Uuid().v4(); // 🔹 إنشاء ID فريد للمنتج

    await FirebaseFirestore.instance.collection('products').doc(productId).set({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'imageUrl': imageUrl, // 🔹 استخدام رابط الصورة المرفوعة
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ تم إضافة المنتج بنجاح"), backgroundColor: Colors.green),
    );

    setState(() {
      _isUploading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة منتج")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceDialog(),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _image == null
                      ? const Center(child: Text("اضغط لاختيار صورة 📷"))
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),

              _buildTextField(_nameController, "اسم المنتج", Icons.shopping_bag),
              const SizedBox(height: 10),
              _buildTextField(_descriptionController, "وصف المنتج", Icons.description),
              const SizedBox(height: 10),
              _buildTextField(_priceController, "السعر", Icons.attach_money, isNumeric: true),
              const SizedBox(height: 20),

              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text("إضافة المنتج"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("اختر من المعرض"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("التقاط صورة بالكاميرا"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return "يرجى إدخال $label";
        if (isNumeric && double.tryParse(value) == null) return "يرجى إدخال قيمة رقمية صحيحة";
        return null;
      },
    );
  }
}
