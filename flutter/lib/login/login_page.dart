import 'package:flutter/material.dart';
import 'package:khmer25/login/auth_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPage(initialMode: AuthMode.login);
  }
}
