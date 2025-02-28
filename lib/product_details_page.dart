import 'package:flutter/material.dart';
import 'add_product_page.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'تفاصيل المنتج'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  product['images'] != null && product['images'].isNotEmpty ? product['images'][0] : '',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['name'] ?? 'اسم غير متوفر',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${product['price'] ?? 'غير متوفر'} DA',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 10),
            Text(
              product['description'] ?? 'لا يوجد وصف متاح',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {}, // TODO: إضافة ميزة التواصل مع البائع
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('💬 تواصل مع البائع', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () async {
          bool? productAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (productAdded == true) {
            // يمكن إضافة إعادة تحميل المنتجات هنا
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
