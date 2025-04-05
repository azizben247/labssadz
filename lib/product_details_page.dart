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

  void _callSeller(String phone) async {
    final Uri callUri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  void _contactWhatsApp(String phone, String productName) async {
    final Uri whatsapp = Uri.parse("https://wa.me/$phone?text=${Uri.encodeFull("مرحبًا، أنا مهتم بشراء $productName")}");
    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp);
    }
  }

  Future<void> _addToWishlist(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productData['id']) // تأكد من أن كل منتج يحتوي على id فريد
          .set(productData);

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

    final String productName = productData['name'] ?? 'بدون اسم';
    final String imageUrl = productData['imageUrl'] ?? '';
    final String price = productData['price'] != null ? "${productData['price']} DA" : 'السعر غير متوفر';
    final String description = productData['description'] ?? 'لا يوجد وصف';
    final String sellerPhone = productData['sellerPhone'] ?? '';
    final String sellerId = productData['sellerId'] ?? '';
    final String sellerName = productData['sellerName'] ?? 'البائع';

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _addToWishlist(context),
            tooltip: "أضف إلى المفضلة",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Text(productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(price, style: const TextStyle(fontSize: 20, color: Colors.deepOrange)),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            if (sellerPhone.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(sellerPhone, style: const TextStyle(fontSize: 16)),
                ],
              ),
            const SizedBox(height: 20),

            if (sellerPhone.isNotEmpty && user != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _callSeller(sellerPhone),
                    icon: const Icon(Icons.call),
                    label: const Text("اتصال"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _contactWhatsApp(sellerPhone, productName),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                    label: const Text("واتساب"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ],
              ),

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
            const SizedBox(height: 20),

            if (sellerId.isNotEmpty && user != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatPage(sellerId: sellerId, sellerName: sellerName)),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text("دردشة مع البائع"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
