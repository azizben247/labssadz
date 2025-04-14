import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help Center"),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text("Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("• How do I post a product?\n• How can I recharge points?\n• How do I contact support?\n"),
          SizedBox(height: 20),
          Text("Need more help?",
              style: TextStyle(fontSize: 16)),
          SizedBox(height: 10),
          Text("Contact us on WhatsApp: +213 667 793 790"),
        ],
      ),
    );
  }
}
