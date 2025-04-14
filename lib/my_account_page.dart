import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final user = FirebaseAuth.instance.currentUser;
  String name = "Loading...";
  String email = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          name = data['name'] ?? user!.displayName ?? 'Labssa User';
          email = user!.email ?? '';
          phone = data['phone'] ?? '';
        });
      }
    }
  }

  Future<void> updateField(String fieldName, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update $fieldName"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );

    if (newValue != null && newValue.trim().isNotEmpty && user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
        fieldName.toLowerCase(): newValue.trim(),
      });

      if (fieldName == 'name') {
        setState(() => name = newValue.trim());
      } else if (fieldName == 'phone') {
        setState(() => phone = newValue.trim());
      }
    }
  }

  void _changePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Current Password"),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _changePassword(
                currentPasswordController.text.trim(),
                newPasswordController.text.trim(),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final cred = EmailAuthProvider.credential(email: user!.email!, password: currentPassword);

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Password updated successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to change password: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Username"),
              subtitle: Text(name),
              trailing: const Icon(Icons.edit),
              onTap: () => updateField("name", name),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Email"),
              subtitle: Text(email),
              enabled: false,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Phone"),
              subtitle: Text(phone.isEmpty ? "Not set" : phone),
              trailing: const Icon(Icons.edit),
              onTap: () => updateField("phone", phone),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              subtitle: const Text("Update your account password"),
              trailing: const Icon(Icons.edit),
              onTap: () => _changePasswordDialog(),
            ),
          ],
        ),
      ),
    );
  }
}
