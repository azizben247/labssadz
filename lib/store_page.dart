import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import 'login_page.dart';


class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ProductListPage(),  // ✅ التحقق من أن الصفحة موجودة
    SearchPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // ✅ التحقق من تسجيل الدخول

    return Scaffold(
      appBar: AppBar(
        title: const Text("المتجر"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // عرض الصفحة المختارة من القائمة السفلية
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'المتجر'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'بحث'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),

      // ✅ إضافة زر "إضافة منتج" يظهر فقط للمستخدمين المسجلين
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddProductPage()),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ✅ تعريف `ProductListPage` داخل `store_page.dart` إذا لم يكن لديك ملف منفصل
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: Image.network(
                        product['image'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${product['price']} DA',
                          style: const TextStyle(fontSize: 14, color: Colors.orange),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ تم طلب المنتج بنجاح!"), backgroundColor: Colors.green),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('شراء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
