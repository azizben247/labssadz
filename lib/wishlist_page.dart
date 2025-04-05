import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض قائمة الأمنيات.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الأمنيات'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wishlist')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('قائمة الأمنيات فارغة.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['imageUrl'] != null
                      ? NetworkImage(data['imageUrl'])
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                title: Text(data['name'] ?? 'منتج بدون اسم'),
                subtitle: Text('${data['price'] ?? 0} DA'),
              );
            },
          );
        },
      ),
    );
  }
}
