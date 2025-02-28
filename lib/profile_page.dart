import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? _userName;
  String? _email;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
          _email = userDoc['email'];
          _profileImageUrl = userDoc['profileImageUrl'];
        });
      }
    }
  }

  /// ✅ اختيار صورة جديدة للبروفايل ورفعها إلى Firebase
  Future<void> _updateProfileImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Reference ref = FirebaseStorage.instance.ref().child('profile_images/${user!.uid}.jpg');
      await ref.putFile(File(pickedFile.path));
      String imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم تحديث صورة البروفايل!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حدث خطأ أثناء التحديث: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// ✅ تسجيل خروج المستخدم
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("الملف الشخصي"), backgroundColor: Colors.orange),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    /// ✅ صورة البروفايل مع زر التحديث
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            backgroundColor: Colors.grey[300],
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showImagePickerDialog(),
                              child: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                radius: 22,
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// ✅ معلومات المستخدم
                    Text(
                      _userName ?? "اسم المستخدم",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      _email ?? "البريد الإلكتروني",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),

                    /// ✅ زر تسجيل الخروج
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("تسجيل الخروج"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Colors.white30),

                    /// ✅ المنتجات المضافة من قبل المستخدم
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("📦 المنتجات المضافة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('userId', isEqualTo: user?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("لا توجد منتجات مضافة بعد", style: TextStyle(color: Colors.white70)));
                        }
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs.map((doc) {
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            return Card(
                              color: Colors.white10,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: Image.network(
                                  data['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.white70),
                                ),
                                title: Text(data['name'], style: const TextStyle(color: Colors.white)),
                                subtitle: Text("${data['price']} DA", style: const TextStyle(color: Colors.orange)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("🗑 تم حذف المنتج"), backgroundColor: Colors.red),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ✅ اختيار صورة البروفايل
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text("اختر من المعرض"),
                onTap: () {
                  _updateProfileImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text("التقاط صورة بالكاميرا"),
                onTap: () {
                  _updateProfileImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
