import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = "All";

  final List<Map<String, String>> categories = [
    {"name": "All", "image": "assets/images/all.png"},
    {"name": "T-Shirts", "image": "assets/images/tshirt.png"},
    {"name": "Jeans", "image": "assets/images/jeans.png"},
    {"name": "Vests", "image": "assets/images/vest.png"},
    {"name": "Accessories", "image": "assets/images/accessories.png"},
    {"name": "Shoes", "image": "assets/images/shoes.png"},
  ];

  final List<Map<String, dynamic>> products = [
    {"name": "قميص رجالي", "price": "2500 DA", "image": "assets/images/tshirt.png", "category": "T-Shirts"},
    {"name": "جينز أزرق", "price": "3500 DA", "image": "assets/images/jeans.png", "category": "Jeans"},
    {"name": "سترة شتوية", "price": "5500 DA", "image": "assets/images/vest.png", "category": "Vests"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("متجر الملابس", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // ✅ عند الضغط، يمكن فتح صفحة الحساب الشخصي بدلاً من تسجيل الخروج
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ مربع البحث
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "🔍 ابحث عن منتج...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // ✅ شريط الفئات
          Container(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category["name"]!;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(category["image"]!),
                          radius: 25,
                        ),
                        const SizedBox(height: 5),
                        Text(category["name"]!, style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ✅ عرض المنتجات مع التصفية والبحث
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                // ✅ تطبيق البحث والتصفية
                if (selectedCategory != "All" && product["category"] != selectedCategory) {
                  return SizedBox.shrink();
                }
                if (_searchController.text.isNotEmpty &&
                    !product["name"].contains(_searchController.text)) {
                  return SizedBox.shrink();
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.asset(product["image"]!, fit: BoxFit.cover),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Text(product["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(product["price"], style: TextStyle(fontSize: 14, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
