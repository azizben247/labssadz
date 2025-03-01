import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'store_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false; // متغير لحفظ خيار تذكر المستخدم

  @override
  void initState() {
    super.initState();
    _loadSavedLogin(); // تحميل بيانات تسجيل الدخول عند فتح التطبيق
  }

  // تحميل بيانات تسجيل الدخول المخزنة
  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');
    bool? remember = prefs.getBool('rememberMe');

    if (savedEmail != null && savedPassword != null && remember == true) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  // تسجيل الدخول وحفظ البيانات إذا تم تحديد خيار "تذكرني"
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // حفظ بيانات تسجيل الدخول إذا اختار المستخدم "تذكرني"
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('email', _emailController.text.trim());
        prefs.setString('password', _passwordController.text.trim());
        prefs.setBool('rememberMe', true);
      } else {
        _clearSavedLogin(); // حذف بيانات تسجيل الدخول إذا لم يتم تحديد الخيار
      }

      // الانتقال إلى الصفحة الرئيسية بعد تسجيل الدخول
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const StorePage()));
    } on FirebaseAuthException catch (e) {
      String errorMessage = "حدث خطأ، حاول مرة أخرى";

      if (e.code == 'user-not-found') {
        errorMessage = "المستخدم غير موجود";
      } else if (e.code == 'wrong-password') {
        errorMessage = "كلمة المرور غير صحيحة";
      } else if (e.code == 'invalid-email') {
        errorMessage = "البريد الإلكتروني غير صالح";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("❌ $errorMessage"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // حذف بيانات تسجيل الدخول من `SharedPreferences`
  Future<void> _clearSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('email');
    prefs.remove('password');
    prefs.remove('rememberMe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية المتدرجة
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

          // صندوق زجاجي أنيق
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
                      "تسجيل الدخول",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // إدخال البريد الإلكتروني
                    _buildTextField(
                        _emailController, "البريد الإلكتروني", Icons.email),
                    const SizedBox(height: 10),

                    // إدخال كلمة المرور
                    _buildTextField(
                        _passwordController, "كلمة المرور", Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 10),

                    // خيار "تذكرني"
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                        ),
                        const Text("تذكرني",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // زر تسجيل الدخول
                    _isLoading
                        ? const CircularProgressIndicator()
                        : _buildLoginButton(),

                    const SizedBox(height: 10),

                    // زر الانتقال إلى صفحة التسجيل
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupPage()));
                      },
                      child: const Text("ليس لديك حساب؟ قم بالتسجيل الآن!",
                          style: TextStyle(color: Colors.white70)),
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

  // عنصر إدخال بيانات احترافي
  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  // زر تسجيل الدخول الاحترافي
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
          ),
        ),
        child: const Text(
          "تسجيل الدخول",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
