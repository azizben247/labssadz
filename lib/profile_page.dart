import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'product_details_page.dart';
import 'recharge_points_page.dart';
import 'my_account_page.dart';
import 'notifications_page.dart';
import 'settings_page.dart';
import 'help_center_page.dart';

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
  int points = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) return;
    print("🔄 Loading user data for: ${user!.uid}");
    final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['name'] ?? user!.displayName ?? 'Labssa User';
        imageUrl = data['imageUrl'];
        points = data['points'] ?? 0;
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

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      "imageUrl": downloadUrl,
    });

    setState(() {
      imageUrl = "$downloadUrl?update=${DateTime.now().millisecondsSinceEpoch}";
    });
  }

  Future<void> updateName(String newName) async {
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      "name": newName,
    });
    setState(() => name = newName);
  }

  Future<void> deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Product deleted")),
    );
  }

  Future<void> markProductAsSold(String productId) async {
    await FirebaseFirestore.instance.collection('sales').add({
      "productId": productId,
      "sellerId": user!.uid,
      "timestamp": Timestamp.now(),
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('sales')
        .where('sellerId', isEqualTo: user!.uid)
        .get();

    int count = snapshot.docs.length;

    if (count > 1) {
      int newPoints = (count - 1) * 10;
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
        "points": newPoints,
      });
      setState(() => points = newPoints);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Sale recorded")),
    );
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider("$imageUrl?updated=${DateTime.now().millisecondsSinceEpoch}")
                                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.deepOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
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
                              icon: const Icon(Icons.edit),
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
                      ),
                    ],
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("رصيدك الحالي", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              "$points نقطة",
                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
                      ],
                    ),
                  ),

                  const Divider(height: 30),
                  _buildOption("My Account", Icons.person, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAccountPage()));
                  }),
                  _buildOption("Notifications", Icons.notifications, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  }),
                  _buildOption("Settings", Icons.settings, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  }),
                  _buildOption("Help Center", Icons.help, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterPage()));
                  }),
                  _buildOption("Recharge Points", Icons.credit_score, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RechargePointsPage()));
                  }),
                  _buildOption("Log Out", Icons.logout, onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pop();
                  }),
                  const Divider(height: 30),
                  const Text("My Products", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 500,
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
                                MaterialPageRoute(builder: (_) => ProductDetailsPage(productData: product)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.attach_money, color: Colors.green),
                                    tooltip: "Record Sale",
                                    onPressed: () => markProductAsSold(id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Delete Product",
                                    onPressed: () => deleteProduct(id),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
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
