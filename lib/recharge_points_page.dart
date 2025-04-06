import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RechargePointsPage extends StatelessWidget {
  const RechargePointsPage({super.key});

  final String baridiMobNumber = "00799999002895624030";
  final String whatsappNumber = "213667793790"; // بدون +

  void _contactOnWhatsApp() async {
    final Uri url = Uri.parse(
      "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent("مرحبًا، أود شحن النقاط في حسابي.")}",
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ لا يمكن فتح واتساب");
    }
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildOffer(String label, String price) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.deepOrange),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("شحن النقاط"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📌 كيفية شحن النقاط:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "لشحن النقاط، يرجى تحويل المبلغ إلى الحساب التالي باستخدام تطبيق بريدي موب، ثم إرسال صورة الإيصال عبر واتساب:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildInfoTile("رقم الحساب البريدي", baridiMobNumber, Icons.account_balance),
            _buildInfoTile("رقم التواصل عبر واتساب", "0667 793 790", Icons.phone),
            const SizedBox(height: 20),
            const Text("🎁 عروض النقاط:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildOffer("1 نقطة", "200 دج"),
            _buildOffer("5 نقاط", "500 دج"),
            _buildOffer("10 نقاط + 2 مجانًا", "1000 دج"),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _contactOnWhatsApp,
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                label: const Text("تواصل عبر واتساب"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
