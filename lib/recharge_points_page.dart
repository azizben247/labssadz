import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RechargePointsPage extends StatelessWidget {
  const RechargePointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recharge Points"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🔁 Recharge Instructions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Transfer the corresponding amount to the account below via BaridiMob. After payment, send a screenshot via WhatsApp to get your points.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepOrange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📌 BaridiMob Account Number:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text("00799999002895624030",
                      style: TextStyle(fontSize: 18, color: Colors.deepOrange)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "🔥 Points Offers",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildOffer("1 Point", "200 DZD"),
            _buildOffer("5 Points", "500 DZD"),
            _buildOffer("10 Points + 2 FREE", "1000 DZD"),
            const SizedBox(height: 30),
            const Text(
              "📤 After payment, please contact us via WhatsApp to confirm your transaction and receive your points.",
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // يمكنك فتح واتساب مباشرة هنا
                  // launchUrl(Uri.parse("https://wa.me/213667793790"));
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                label: const Text("Contact Admin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOffer(String points, String price) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(points, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(price, style: const TextStyle(fontSize: 16, color: Colors.deepOrange)),
        ],
      ),
    );
  }
}
