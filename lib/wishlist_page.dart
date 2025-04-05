import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_details_page.dart'; // تأكد أنك أضفت هذا الاستيراد

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('الرجاء تسجيل الدخول لعرض المفضلة.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة الأمنيات"),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("قائمة الأمنيات فارغة."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(productData: data),
                    ),
                  );
                },
                child: Card(
                  color: const Color(0xFFF9F1FD),
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: data['imageUrl'] != null
                        ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 40),
                    title: Text(data['name'] ?? "منتج"),
                    subtitle: Text("${data['price'] ?? ''} DA"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('wishlist')
                            .doc(data['id'])
                            .delete();
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
