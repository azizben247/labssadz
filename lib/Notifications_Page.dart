import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text("You have no notifications at the moment.",
            style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
