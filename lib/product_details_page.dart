import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_page.dart';
import 'login_page.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductDetailsPage({super.key, required this.productData});

  void _contactWhatsApp(BuildContext context, String phone, String productName) async {
    final formattedPhone = phone.startsWith("0") ? phone.replaceFirst("0", "") : phone;
    final fullPhone = "+213$formattedPhone";
    final Uri whatsapp = Uri.parse(
        "https://wa.me/$fullPhone?text=${Uri.encodeFull("مرحبًا، أنا مهتم بشراء $productName")}");

    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تعذر فتح واتساب")),
      );
    }
  }

  void _callSeller(String phone) async {
    final Uri callUri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Future<void> _addToWishlist(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    try {
      String productId = productData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId)
          .set({
        'id': productId,
        'name': productData['name'] ?? '',
        'imageUrl': productData['imageUrl'] ?? '',
        'price': productData['price'] ?? '',
        'description': productData['description'] ?? '',
        'sellerId': productData['sellerId'] ?? '',
        'sellerPhone': productData['sellerPhone'] ?? '',
        'sellerName': productData['sellerName'] ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم الإضافة إلى المفضلة"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل الإضافة إلى المفضلة: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String productName = productData['name'] ?? 'No name';
    final String imageUrl = productData['imageUrl'] ?? '';
    final String price = productData['price'] != null ? "${productData['price']} DA" : 'Not available';
    final String description = productData['description'] ?? 'No description';
    final String sellerPhone = productData['sellerPhone'] ?? '';
    final String sellerId = productData['sellerId'] ?? '';
    final String sellerName = productData['sellerName'] ?? 'Seller';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text(productName),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _addToWishlist(context),
            tooltip: "Add to Wishlist",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ صورة المنتج
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // 📦 اسم المنتج + السعر
            Text(productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 20, color: Colors.deepOrange)),

            const SizedBox(height: 20),
            // 📝 الوصف
            const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            // ☎️ معلومات التواصل
            if (sellerPhone.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Contact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(sellerPhone, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _callSeller(sellerPhone),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _contactWhatsApp(context, sellerPhone, productName),
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 30),

            if (user == null)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text("Login to Contact"),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                ),
              ),

            if (sellerId.isNotEmpty && user != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatPage(sellerId: sellerId, sellerName: sellerName)),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat with Seller"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
