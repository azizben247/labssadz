import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = "العربية";
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// ✅ تحميل الإعدادات المخزنة مسبقًا
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? "العربية";
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  /// ✅ تغيير اللغة وتحديث الإعدادات
  void _changeLanguage(String? lang) async {
    if (lang != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
      setState(() {
        _selectedLanguage = lang;
      });
    }
  }

  /// ✅ تغيير وضع الإضاءة وحفظ التفضيلات
  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  /// ✅ تأكيد تسجيل الخروج
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("تسجيل الخروج"),
          content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("خروج"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("الإعدادات", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          /// ✅ تغيير اللغة
          ListTile(
            title: const Text("تغيير اللغة", style: TextStyle(fontSize: 18)),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: _changeLanguage,
              items: ["العربية", "English"].map((String lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
            ),
          ),

          /// ✅ تبديل الوضع الليلي
          SwitchListTile(
            title: const Text("الوضع الليلي", style: TextStyle(fontSize: 18)),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            activeColor: Colors.orange,
          ),

          /// ✅ زر تسجيل الخروج
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("تسجيل الخروج", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
