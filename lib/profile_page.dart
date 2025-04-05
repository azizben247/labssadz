import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'product_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? name;
  String? imageUrl;
  bool isLoading = true;

  Future<void> fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['name'] ?? user!.displayName ?? 'Labssa User';
        imageUrl = data['imageUrl'];
        isLoading = false;
      });
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final ref = FirebaseStorage.instance.ref().child("user_images/${user!.uid}");
    await ref.putFile(File(file.path));
    final downloadUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({"imageUrl": downloadUrl});
    setState(() => imageUrl = downloadUrl);
  }

  Future<void> updateName(String newName) async {
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({"name": newName});
    setState(() => name = newName);
  }

  Future<int> getSalesCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("sales")
        .where("sellerId", isEqualTo: user!.uid)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getPoints() async {
    final sales = await getSalesCount();
    return sales <= 1 ? 0 : ((sales - 1) * 10); // المبيعة الأولى مجانية
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection("products").doc(productId).delete();
  }

  @override
  void initState() {
    fetchUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Please login."));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text("Profile"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: pickAndUploadImage,
                        child: CircleAvatar(
                          radius: 35,
                          backgroundImage: imageUrl != null
                              ? NetworkImage(imageUrl!)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(name ?? "Labssa User",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final controller = TextEditingController(text: name);
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Edit Name"),
                                    content: TextField(controller: controller),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, controller.text),
                                          child: const Text("Save")),
                                    ],
                                  ),
                                );
                                if (newName != null && newName.trim().isNotEmpty) {
                                  await updateName(newName.trim());
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                    future: getPoints(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat("Points", snapshot.data!),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 30),
                  _buildOption("My Account", Icons.person),
                  _buildOption("Notifications", Icons.notifications),
                  _buildOption("Settings", Icons.settings),
                  _buildOption("Help Center", Icons.help),
                  _buildOption("Log Out", Icons.logout, onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                  }),
                  const Divider(height: 30),
                  const Text("My Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('userId', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final product = docs[index].data() as Map<String, dynamic>;
                            final id = docs[index].id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(product['imageUrl']),
                              ),
                              title: Text(product['name']),
                              subtitle: Text("${product['price']} DA"),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProductDetailsPage(productData: product))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.attach_money, color: Colors.green),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection("sales").add({
                                        "productId": id,
                                        "sellerId": user!.uid,
                                        "timestamp": Timestamp.now(),
                                      });
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await deleteProduct(id);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildOption(String label, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepOrange),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text("$value", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
