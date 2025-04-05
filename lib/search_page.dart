import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];

  void _searchProducts(String query) async {
    final results = await FirebaseFirestore.instance
        .collection('products')
        .get();

    setState(() {
      _searchResults = results.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔍 البحث"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: "اكتب اسم المنتج...",
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text("لا توجد نتائج"))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final data = _searchResults[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: data['imageUrl'] != null
                            ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                        title: Text(data['name'] ?? 'بدون اسم'),
                        subtitle: Text("${data['price']} DA"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsPage(productData: data),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
