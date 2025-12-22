import 'package:flutter/material.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'signup_page.dart'; // <-- ADD THIS

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final phone = phoneController.text.trim();
      final pass = passwordController.text.trim();

      if (phone.isEmpty || pass.isEmpty) {
        throw Exception(LangStore.t('login.error.required'));
      }

      final res = await ApiService.loginUser(phone: phone, password: pass);
      // Ensure we keep the phone the user typed even if backend omits it
      final parsed = AppUser.fromJson(res);
      final user = AppUser(
        id: parsed.id,
        username: parsed.username,
        firstName: parsed.firstName,
        lastName: parsed.lastName,
        email: parsed.email,
        phone: parsed.phone.isNotEmpty ? parsed.phone : phone,
        avatarUrl: parsed.avatarUrl,
      );
      await AuthStore.setUser(user, token: res['token']?.toString());
      await AnalyticsService.identifyUser(
        userId: user.id.toString(),
        email: user.email,
        locale: LangStore.current.value.name,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LangStore.t('login.success'))));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${LangStore.t('common.error')}: $e")),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 80),

              // LOGO
              Image.asset(
                "assets/images/logo.jpg",
                height: 120,
                errorBuilder: (_, __, ___) =>
                    Image.asset("assets/images/logo1.png", height: 120),
              ),

              const SizedBox(height: 25),

              Text(
                LangStore.t('login.welcomeBack'),
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // LOGIN CARD
              Center(
                child: Container(
                  width: 380,
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LangStore.t('login.title'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PHONE TEXTFIELD
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: LangStore.t('login.phone'),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PASSWORD
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: LangStore.t('login.password'),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // REMEMBER + FORGOT
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (v) => setState(() => rememberMe = v!),
                          ),
                          Text(LangStore.t('login.remember')),
                          const Spacer(),
                          Text(
                            LangStore.t('login.forgot'),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: loading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  LangStore.t('login.button'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(LangStore.t('login.noAccount')),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              LangStore.t('login.signup'),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
