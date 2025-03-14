import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

// ✅ Correct conditional import to fix 'getFile' error
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
  final _formKey = GlobalKey<FormState>();

  XFile? _pickedFile;
  Uint8List? _imageBytes; // Stores image data for web
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) {
      print("❌ Error: No image selected");
      return;
    }

    if (kIsWeb) {
      Uint8List? webImageBytes = await pickedFile.readAsBytes();
      if (webImageBytes == null) {
        print("❌ Error: Failed to read image bytes (Web)");
        return;
      }

      setState(() {
        _pickedFile = pickedFile;
        _imageBytes = webImageBytes; // ✅ Ensure image bytes are set
      });

      print("✅ Image selected and bytes loaded successfully (Web)");
    } else {
      setState(() {
        _pickedFile = pickedFile;
      });

      print("✅ Image selected successfully (Mobile)");
    }
  }

  Future<void> _uploadImage() async {
    print("📤 Uploading Product...");

    if (_pickedFile == null) {
      print("❌ Error: No file selected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No file selected!")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String fileName =
          "product_images/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask;

      if (kIsWeb) {
        if (_imageBytes == null) {
          print("❌ Error: _imageBytes is NULL before upload (Web)");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error: Image is NULL")),
          );
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
          print("❌ Error: getFile() returned null (Mobile)");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error: Could not get file")),
          );
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
      print("✅ Image Upload Success: $downloadUrl");

      // ✅ Get Current User ID
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

      // ✅ Save Product Details in Firestore
      await FirebaseFirestore.instance.collection("products").add({
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "imageUrl": downloadUrl,
        "userId": userId, // ✅ Links product to the logged-in user
        "timestamp": FieldValue.serverTimestamp(), // ✅ Sort products by time
      });

      print("✅ Product saved to Firestore");

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product uploaded successfully!")),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, downloadUrl); // Navigate back & return URL
      }
    } catch (e) {
      print("❌ Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
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
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                  ),
                  child: _pickedFile == null
                      ? const Center(child: Text("Select Image 📷"))
                      : kIsWeb
                          ? (_imageBytes == null
                              ? const Center(
                                  child: Text("❌ Error: Image is Null"))
                              : Image.memory(_imageBytes!, fit: BoxFit.cover))
                          : Image.file(getFile(_pickedFile!)!,
                              fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                  _nameController, "Product Name", Icons.shopping_bag),
              const SizedBox(height: 10),
              _buildTextField(
                  _descriptionController, "Description", Icons.description),
              const SizedBox(height: 10),
              _buildTextField(_priceController, "Price", Icons.attach_money,
                  isNumeric: true),
              const SizedBox(height: 20),
              _isUploading
                  ? const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Uploading... Please wait"),
                      ],
                    ) // ✅ Show spinner & text
                  : ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : _uploadImage, // ✅ Disable button when uploading
                      icon: const Icon(Icons.add),
                      label: const Text("Add Product"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUploading
                            ? Colors.grey
                            : Colors.orange, // ✅ Grey when disabled
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value!.isEmpty) return "Please enter $label";
        if (isNumeric && double.tryParse(value) == null)
          return "Enter a valid number";
        return null;
      },
    );
  }
}
