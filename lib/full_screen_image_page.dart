import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String sellerPhone;

  const FullScreenImagePage({super.key, required this.imageUrl, required this.sellerPhone});

  void _callSeller() async {
    if (sellerPhone.isNotEmpty) {
      final Uri callUri = Uri.parse("tel:$sellerPhone");
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        print("❌ لا يمكن إجراء المكالمة");
      }
    }
  }

  void _contactSellerOnWhatsApp() async {
    if (sellerPhone.isNotEmpty) {
      final Uri whatsappUri = Uri.parse(
          "https://wa.me/$sellerPhone?text=${Uri.encodeFull("مرحبًا، أنا مهتم بشراء هذا المنتج. هل هو متاح؟")}");
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        print("❌ لا يمكن فتح واتساب");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _callSeller,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text("📞 اتصال"),
                ),
                ElevatedButton.icon(
                  onPressed: _contactSellerOnWhatsApp,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.message, color: Colors.white),
                  label: const Text("💬 واتساب"),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
