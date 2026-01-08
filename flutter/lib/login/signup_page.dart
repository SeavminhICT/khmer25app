import 'package:flutter/material.dart';
import 'package:khmer25/login/auth_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthPage(initialMode: AuthMode.register);
  }
}
