import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'add_product_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  runApp(const ClothingApp());
}

class ClothingApp extends StatelessWidget {
  const ClothingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clothing Store',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// شاشة البداية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CategoryPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported,
                          size: 100, color: Colors.grey);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Labssa DZ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// صفحة التصنيفات
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'T-Shirts', 'image': 'assets/tishrt.png'},
    {'name': 'Jeans', 'image': 'assets/jeans.png'},
    {'name': 'Vests', 'image': 'assets/vast.png'},
    {'name': 'Accessories', 'image': 'assets/watch.png'},
    {'name': 'Shoes', 'image': 'assets/shoes.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported,
                    size: 30, color: Colors.grey);
              },
            ),
            const SizedBox(width: 10),
            const Text('Labssa DZ',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(
                          category: categories[index]['name'])),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            categories[index]['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported,
                                  size: 80, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        categories[index]['name'],
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const CategoryPage()));
          } else if (index == 1) {
            // مثال: الانتقال إلى صفحة العربة
            // Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 28), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28), label: 'Profile'),
        ],
      ),
    );
  }
}

// صفحة تفاصيل المنتجات
class ProductDetailsPage extends StatelessWidget {
  final String category;

  const ProductDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Details'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/${category.toLowerCase()}.png',
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported,
                    size: 100, color: Colors.grey);
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Explore our latest collection of $category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
} 