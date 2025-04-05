import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_page.dart';
import 'wishlist_page.dart';
import 'cart_page.dart';
import 'product_details_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'add_product_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  _StorePageState createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int _currentIndex = 0;
  String _selectedCategory = "all";
  final List<String> _categories = ["all", "vest", "accessoire", "shoes", "T-shirt", "jeans"];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          elevation: 0,
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 30,
              ),
              const SizedBox(width: 10),
              const Text(
                "Labssa DZ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  // أضف هنا صفحة البحث إن توفرت
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("قريبًا!")));
                },
              ),
              if (user != null)
  GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
    },
    child: const CircleAvatar(
               backgroundImage: AssetImage('assets/images/default_avatar.png'),
               radius: 18,
              ),
              )
              else
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                  child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            // التصنيفات
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = _categories[index];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: _selectedCategory == _categories[index]
                            ? Colors.deepOrange
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedCategory == _categories[index] ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(child: ProductList(category: _selectedCategory)),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
onTap: (index) {
  setState(() {
    _currentIndex = index;
  });

  if (index == 1) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
  } else if (index == 2) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
  } else if (index == 3) {
    // يمكنك ربطه بالبروفايل مثلاً أو حذفه
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
  }
},
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Wishlist'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
        floatingActionButton: user != null
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
                },
                backgroundColor: Colors.deepOrange,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

// ✅ قائمة المنتجات
class ProductList extends StatelessWidget {
  final String category;

  const ProductList({super.key, required this.category});

  void _contactSeller(String phone) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeFull("مرحبًا، أنا مهتم بالمنتج الخاص بك")}");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final products = snapshot.data!.docs.where((product) {
          final data = product.data() as Map<String, dynamic>;
          return category == "all" || data['category'] == category;
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
            var product = products[index];
            Map<String, dynamic> productData = product.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsPage(productData: productData),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: productData['imageUrl'] ?? "",
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(productData['name'] ?? "No name",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${productData['price']} DA",
                              style: const TextStyle(color: Colors.deepOrange)),
                          const SizedBox(height: 5),
                          ElevatedButton.icon(
                            icon: Icon(user != null ? Icons.message : Icons.lock),
                            label: Text(user != null ? "WhatsApp" : "Login to Contact"),
                            onPressed: () {
                              if (user == null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                );
                              } else {
                                _contactSeller(productData['sellerPhone'] ?? "");
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
