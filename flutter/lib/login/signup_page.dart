import 'package:flutter/material.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LangStore.t('common.error'),
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(LangStore.t('dialog.ok')),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                LangStore.t('signup.success'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                LangStore.t('signup.success.desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: Text(
                  LangStore.t('dialog.ok'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> handleCreateAccount() async {
    String first = firstNameController.text.trim();
    String last = lastNameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String pass = passwordController.text.trim();
    String confirm = confirmPasswordController.text.trim();

    if (first.isEmpty ||
        last.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty ||
        confirm.isEmpty) {
      showErrorDialog(LangStore.t('signup.error.required'));
      return;
    }

    if (pass != confirm) {
      showErrorDialog(LangStore.t('signup.error.mismatch'));
      return;
    }

    try {
      final res = await ApiService.registerUser(
        firstName: first,
        lastName: last,
        email: email,
        phone: phone,
        password: pass,
      );
      final parsed = AppUser.fromJson(res);
      final user = AppUser(
        id: parsed.id,
        username: parsed.username,
        firstName: parsed.firstName.isNotEmpty ? parsed.firstName : first,
        lastName: parsed.lastName.isNotEmpty ? parsed.lastName : last,
        email: parsed.email.isNotEmpty ? parsed.email : email,
        phone: parsed.phone.isNotEmpty ? parsed.phone : phone,
        avatarUrl: parsed.avatarUrl,
      );
      await AuthStore.setUser(user, token: res['token']?.toString());
      await AnalyticsService.identifyUser(
        userId: user.id.toString(),
        email: user.email,
        locale: LangStore.current.value.name,
      );
      showSuccessDialog();
    } catch (e) {
      showErrorDialog("${LangStore.t('common.error')}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    LangStore.t('signup.create'),
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: 380,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    buildField(
                      LangStore.t('signup.firstName'),
                      firstNameController,
                    ),
                    const SizedBox(height: 20),
                    buildField(
                      LangStore.t('signup.lastName'),
                      lastNameController,
                    ),
                    const SizedBox(height: 20),
                    buildField(LangStore.t('signup.email'), emailController),
                    const SizedBox(height: 20),
                    buildField(LangStore.t('signup.phone'), phoneController),
                    const SizedBox(height: 20),
                    buildField(
                      LangStore.t('signup.password'),
                      passwordController,
                      obscure: true,
                    ),
                    const SizedBox(height: 20),
                    buildField(
                      LangStore.t('signup.confirm'),
                      confirmPasswordController,
                      obscure: true,
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: Text(
                          LangStore.t('signup.submit'),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LangStore.t('signup.haveAccount'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: Text(
                      LangStore.t('signup.signIn'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
