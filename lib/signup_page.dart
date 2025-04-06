import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': Timestamp.now(),
        'points': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم إنشاء الحساب بنجاح! ✅"), backgroundColor: Colors.green),
      );

      // الانتقال إلى صفحة تسجيل الدخول
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتحركة
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.pinkAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // شكل الزجاج
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "إنشاء حساب جديد",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // إدخال الاسم
                    _buildTextField(_nameController, "الاسم", Icons.person),
                    const SizedBox(height: 10),

                    // إدخال البريد الإلكتروني
                    _buildTextField(_emailController, "البريد الإلكتروني", Icons.email),
                    const SizedBox(height: 10),

                    // إدخال كلمة المرور
                    _buildTextField(_passwordController, "كلمة المرور", Icons.lock, isPassword: true),
                    const SizedBox(height: 20),

                    // زر التسجيل
                    _isLoading
                        ? const CircularProgressIndicator()
                        : _buildSignupButton(),

                    const SizedBox(height: 10),

                    // زر الانتقال لتسجيل الدخول
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      child: const Text("لديك حساب بالفعل؟ تسجيل الدخول", style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // عنصر إدخال نص متقدم
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return "يرجى إدخال $label";
        if (label == "البريد الإلكتروني" && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return "يرجى إدخال بريد إلكتروني صحيح";
        }
        if (label == "كلمة المرور" && value.length < 6) {
          return "يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل";
        }
        return null;
      },
    );
  }

  // زر التسجيل الاحترافي
  Widget _buildSignupButton() {
    return GestureDetector(
      onTap: _signup,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Text(
          "تسجيل",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
