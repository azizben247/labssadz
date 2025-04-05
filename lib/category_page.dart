import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_page.dart';

class CategoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("❌ خطأ في جلب البيانات: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("🛒 لا توجد منتجات متاحة حالياً!", style: TextStyle(fontSize: 18)),
          );
        }

        // ✅ تصنيف المنتجات حسب الفئة
        Map<String, List<DocumentSnapshot>> categorizedProducts = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String category = data['category'] ?? "غير مصنف";
          
          if (!categorizedProducts.containsKey(category)) {
            categorizedProducts[category] = [];
          }
          categorizedProducts[category]!.add(doc);
        }

        return ListView(
          children: categorizedProducts.keys.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ عرض صورة الفئة وعنوانها
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      CachedNetworkImage(
                        imageUrl: _getCategoryImage(category), // جلب الصورة الخاصة بالفئة
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ),

                // ✅ المنتجات الخاصة بهذه الفئة
                Container(
                  height: 250, // لجعل المنتجات تظهر أفقياً تحت الصورة
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorizedProducts[category]!.length,
                    itemBuilder: (context, index) {
                      var productData = categorizedProducts[category]![index].data() as Map<String, dynamic>;
                      String imageUrl = productData['imageUrl'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(product: productData),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                          margin: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: Uri.encodeFull(imageUrl),
                                    width: 150,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) {
                                      print("❌ فشل تحميل الصورة: $url");
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
                                      productData['name'] ?? 'اسم غير متوفر',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${productData['price'] ?? 0} DA',
                                      style: const TextStyle(fontSize: 14, color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // ✅ دالة للحصول على صورة الفئة
  String _getCategoryImage(String category) {
    Map<String, String> categoryImages = {
      'T-Shirts': 'https://your-storage-link/tshirts.png',
      'Jeans': 'https://your-storage-link/jeans.png',
      'Vests': 'https://your-storage-link/vests.png',
      'Shoes': 'https://your-storage-link/shoes.png',
      'Watch': 'https://your-storage-link/watch.png',
    };

    return categoryImages[category] ?? 'https://via.placeholder.com/150';
  }
}
