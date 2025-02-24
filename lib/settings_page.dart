import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('اللغة'),
            subtitle: Text('العربية'),
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('الإشعارات'),
            subtitle: Text('مفعّلة'),
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('الدعم والمساعدة'),
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('حول التطبيق'),
          ),
        ],
      ),
    );
  }
}
