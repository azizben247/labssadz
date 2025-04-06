import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'file_helper.dart' if (dart.library.io) 'file_helper_io.dart';
import 'recharge_points_page.dart'; // تأكد من استيراد الصفحة

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _selectedCategory;

  final List<String> _categories = ["jeans", "tshirt", "vest", "accessoire", "shoes", "all"];
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedFile = file;
        _imageBytes = bytes;
      });
    } else {
      setState(() {
        _pickedFile = file;
      });
    }
  }

  Future<int> _getProductCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: user!.uid)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getUserPoints() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    return (doc.data()?['points'] ?? 0) as int;
  }

  Future<void> _deductPoint() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'points': FieldValue.increment(-1),
    });
  }

  Future<void> _uploadProduct() async {
    if (_pickedFile == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and category.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final count = await _getProductCount();
      final points = await _getUserPoints();

      if (count >= 1 && points < 1) {
        setState(() => _isUploading = false);

        // 🟠 تنبيه احترافي وتحويل إلى صفحة الشحن
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("رصيد النقاط غير كافٍ"),
            content: const Text("لقد استهلكت المنتج المجاني. يُرجى شحن نقاطك لإضافة منتج جديد."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargePointsPage()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: const Text("شحن النقاط"),
              ),
            ],
          ),
        );
        return;
      }

      String fileName = "products/${_selectedCategory}/${Uuid().v4()}";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = getFile(_pickedFile!);
        uploadTask = ref.putFile(file!, SettableMetadata(contentType: 'image/jpeg'));
      }

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      if (count >= 1) {
        await _deductPoint();
      }

      await FirebaseFirestore.instance.collection("products").add({
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "sellerPhone": _phoneController.text.trim(),
        "category": _selectedCategory!,
        "imageUrl": imageUrl,
        "userId": user!.uid,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Please login."));

    return Scaffold(
      appBar: AppBar(title: const Text("Add Product"), backgroundColor: Colors.deepOrange),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: _pickedFile == null
                      ? const Center(child: Text("Tap to select image"))
                      : kIsWeb
                          ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                          : Image.file(getFile(_pickedFile!)!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(_nameController, "Product Name", Icons.shopping_bag),
              const SizedBox(height: 10),
              _buildTextField(_descController, "Description", Icons.description),
              const SizedBox(height: 10),
              _buildTextField(_priceController, "Price", Icons.price_change, isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(_phoneController, "Phone", Icons.phone, isNumber: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Category"),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 20),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _uploadProduct,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Product"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter $label";
        if (isNumber && double.tryParse(value) == null) return "Please enter a valid number";
        return null;
      },
    );
  }
}
