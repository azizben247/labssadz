import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'profile_page.dart';
import 'wishlist_page.dart';
import 'product_details_page.dart';
import 'login_page.dart';
import 'add_product_page.dart';
import 'dart:async';


class StorePage extends StatefulWidget {
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  String _selectedCategory = "all";
  String _searchText = "";
  String userName = "Labssa User";
  StreamSubscription<User?>? _authSubscription;
  String? userImage;

  final List<Map<String, String>> _categories = [
    {'label': 'all', 'image': 'assets/images/categories/all.png'},
    {'label': 'vest', 'image': 'assets/images/categories/vest.png'},
    {'label': 'shoes', 'image': 'assets/images/categories/shoes.png'},
    {'label': 'jeans', 'image': 'assets/images/categories/jeans.png'},
    {'label': 'T-shirt', 'image': 'assets/images/categories/tshirt.png'},
    {'label': 'accessoire', 'image': 'assets/images/categories/accessoire.png'},
  ];

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        setState(() {
          userName = "Labssa User";
          userImage = null;
        });
      } else {
        fetchUserName();
      }
    });

    fetchUserName(); // Initial fetch
  }


  Future<void> fetchUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      final data = doc.data();
      if (data != null && data.containsKey("name")) {
        setState(() {
          userName = data["name"];
          userImage = data["imageUrl"]; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 30),
            const SizedBox(width: 10),
            const Text("Labssa DZ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            const Spacer(),
            if (user != null)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: userImage != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(userImage!),
                      radius: 18,
                    )
                  : const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.deepOrange),
                    ),

                )
            else
              TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hello, Welcome 👋", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchText = value.toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: "Search clothes...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat["label"];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat["label"]!),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(cat["image"]!, height: 35),
                        const SizedBox(height: 5),
                        Text(
                          cat["label"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: ProductList(category: _selectedCategory, searchText: _searchText)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          final user = FirebaseAuth.instance.currentUser;
          setState(() => _currentIndex = index);

          if (index == 1) {
            if (user != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
            } else {
              _showLoginRequiredDialog();
            }
          } else if (index == 2) {
            if (user != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            } else {
              _showLoginRequiredDialog();
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage())),
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }


  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الدخول مطلوب"),
        content: const Text("الرجاء تسجيل الدخول للوصول إلى هذه الصفحة."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: const Text("تسجيل الدخول"),
          ),
        ],
      ),
    );
  }

}

class ProductList extends StatelessWidget {
  final String category;
  final String searchText;

  const ProductList({super.key, required this.category, required this.searchText});

  void _contactSeller(String phone) async {
    final Uri uri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeFull("مرحبًا، أنا مهتم بالمنتج الخاص بك")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final matchesSearch = searchText.isEmpty || name.contains(searchText);
          final matchesCategory = category == "all" || data['category'] == category;
          return matchesSearch && matchesCategory;
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final data = products[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailsPage(productData: data)),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: data['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${data['price']} DA", style: const TextStyle(color: Colors.deepOrange)),
                          const SizedBox(height: 5),
                          ElevatedButton.icon(
                            icon: Icon(user != null ? Icons.message : Icons.lock),
                            label: Text(user != null ? "WhatsApp" : "Login"),
                            onPressed: () {
                              if (user == null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                              } else {
                                _contactSeller(data['sellerPhone'] ?? "");
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
