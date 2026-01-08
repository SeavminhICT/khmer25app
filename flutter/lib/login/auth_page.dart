import 'dart:math';

import 'package:flutter/material.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';
import 'package:khmer25/services/analytics_service.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  final AuthMode initialMode;

  const AuthPage({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final registerPhoneController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final loginPhoneFocus = FocusNode();
  final loginPasswordFocus = FocusNode();
  final registerFirstNameFocus = FocusNode();
  final registerLastNameFocus = FocusNode();
  final registerEmailFocus = FocusNode();
  final registerPhoneFocus = FocusNode();
  final registerPasswordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  late AnimationController _loginShake;
  late AnimationController _registerShake;

  bool rememberMe = false;
  bool _isLogin = true;
  bool _slideFromRight = true;
  bool _loginLoading = false;
  bool _registerLoading = false;

  String? _loginPhoneError;
  String? _loginPasswordError;
  String? _loginFormError;

  String? _registerFirstNameError;
  String? _registerLastNameError;
  String? _registerEmailError;
  String? _registerPhoneError;
  String? _registerPasswordError;
  String? _registerConfirmError;
  String? _registerFormError;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialMode == AuthMode.login;
    _loginShake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _registerShake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    registerPhoneController.dispose();
    registerPasswordController.dispose();
    confirmPasswordController.dispose();

    loginPhoneFocus.dispose();
    loginPasswordFocus.dispose();
    registerFirstNameFocus.dispose();
    registerLastNameFocus.dispose();
    registerEmailFocus.dispose();
    registerPhoneFocus.dispose();
    registerPasswordFocus.dispose();
    confirmPasswordFocus.dispose();

    _loginShake.dispose();
    _registerShake.dispose();
    super.dispose();
  }

  void _toggleMode(bool toLogin) {
    if (_isLogin == toLogin) return;
    setState(() {
      _slideFromRight = toLogin;
      _isLogin = toLogin;
    });
  }

  void _triggerShake(AnimationController controller) {
    controller.forward(from: 0);
  }

  bool _validateLogin() {
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    setState(() {
      _loginPhoneError = phone.isEmpty ? LangStore.t('login.error.required') : null;
      _loginPasswordError =
          pass.isEmpty ? LangStore.t('login.error.required') : null;
      _loginFormError = null;
    });

    final hasError = _loginPhoneError != null || _loginPasswordError != null;
    if (hasError) {
      _triggerShake(_loginShake);
    }
    return !hasError;
  }

  bool _validateRegister() {
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = registerPhoneController.text.trim();
    final pass = registerPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    setState(() {
      _registerFirstNameError =
          first.isEmpty ? LangStore.t('signup.error.required') : null;
      _registerLastNameError =
          last.isEmpty ? LangStore.t('signup.error.required') : null;
      _registerEmailError =
          email.isEmpty ? LangStore.t('signup.error.required') : null;
      _registerPhoneError =
          phone.isEmpty ? LangStore.t('signup.error.required') : null;
      _registerPasswordError =
          pass.isEmpty ? LangStore.t('signup.error.required') : null;
      _registerConfirmError =
          confirm.isEmpty ? LangStore.t('signup.error.required') : null;
      if (pass.isNotEmpty && confirm.isNotEmpty && pass != confirm) {
        _registerConfirmError = LangStore.t('signup.error.mismatch');
      }
      _registerFormError = null;
    });

    final hasError = _registerFirstNameError != null ||
        _registerLastNameError != null ||
        _registerEmailError != null ||
        _registerPhoneError != null ||
        _registerPasswordError != null ||
        _registerConfirmError != null;

    if (hasError) {
      _triggerShake(_registerShake);
    }
    return !hasError;
  }

  Future<void> _login() async {
    if (!_validateLogin()) return;

    setState(() => _loginLoading = true);
    try {
      final phone = phoneController.text.trim();
      final pass = passwordController.text.trim();

      final res = await ApiService.loginUser(phone: phone, password: pass);
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LangStore.t('login.success'))),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _loginFormError = "${LangStore.t('common.error')}: $e";
      });
      _triggerShake(_loginShake);
    }
    setState(() => _loginLoading = false);
  }

  Future<void> _register() async {
    if (!_validateRegister()) return;

    setState(() => _registerLoading = true);
    try {
      final res = await ApiService.registerUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        phone: registerPhoneController.text.trim(),
        password: registerPasswordController.text.trim(),
      );
      final parsed = AppUser.fromJson(res);
      final user = AppUser(
        id: parsed.id,
        username: parsed.username,
        firstName: parsed.firstName.isNotEmpty
            ? parsed.firstName
            : firstNameController.text.trim(),
        lastName: parsed.lastName.isNotEmpty
            ? parsed.lastName
            : lastNameController.text.trim(),
        email: parsed.email.isNotEmpty
            ? parsed.email
            : emailController.text.trim(),
        phone: parsed.phone.isNotEmpty
            ? parsed.phone
            : registerPhoneController.text.trim(),
        avatarUrl: parsed.avatarUrl,
      );
      await AuthStore.setUser(user, token: res['token']?.toString());
      await AnalyticsService.identifyUser(
        userId: user.id.toString(),
        email: user.email,
        locale: LangStore.current.value.name,
      );

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _registerFormError = "${LangStore.t('common.error')}: $e";
      });
      _triggerShake(_registerShake);
    }
    setState(() => _registerLoading = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2C9E6C), size: 72),
              const SizedBox(height: 16),
              Text(
                LangStore.t('signup.success'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                LangStore.t('signup.success.desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6D7A72)),
              ),
              const SizedBox(height: 20),
              AnimatedActionButton(
                label: LangStore.t('dialog.ok'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 520 ? 440.0 : screenWidth * 0.88;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5EFEA),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F4F2),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/images/logo.jpg',
                      height: 80,
                      errorBuilder: (_, __, ___) =>
                          Image.asset('assets/images/logo1.png', height: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LangStore.t('login.welcomeBack'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? LangStore.t('login.title')
                          : LangStore.t('signup.create'),
                      style: const TextStyle(color: Color(0xFF6D7A72)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AuthModeToggle(
                            isLogin: _isLogin,
                            onChanged: _toggleMode,
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              final tween = Tween<Offset>(
                                begin: Offset(_slideFromRight ? 0.18 : -0.18, 0),
                                end: Offset.zero,
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: tween.animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _isLogin
                                ? _LoginForm(
                                    key: const ValueKey('login'),
                                    phoneController: phoneController,
                                    passwordController: passwordController,
                                    phoneFocus: loginPhoneFocus,
                                    passwordFocus: loginPasswordFocus,
                                    rememberMe: rememberMe,
                                    onRememberChanged: (value) {
                                      setState(() => rememberMe = value);
                                    },
                                    phoneError: _loginPhoneError,
                                    passwordError: _loginPasswordError,
                                    formError: _loginFormError,
                                    onSubmit: _login,
                                    loading: _loginLoading,
                                    shakeAnimation: _loginShake,
                                  )
                                : _RegisterForm(
                                    key: const ValueKey('register'),
                                    firstNameController: firstNameController,
                                    lastNameController: lastNameController,
                                    emailController: emailController,
                                    phoneController: registerPhoneController,
                                    passwordController: registerPasswordController,
                                    confirmController: confirmPasswordController,
                                    firstNameFocus: registerFirstNameFocus,
                                    lastNameFocus: registerLastNameFocus,
                                    emailFocus: registerEmailFocus,
                                    phoneFocus: registerPhoneFocus,
                                    passwordFocus: registerPasswordFocus,
                                    confirmFocus: confirmPasswordFocus,
                                    firstNameError: _registerFirstNameError,
                                    lastNameError: _registerLastNameError,
                                    emailError: _registerEmailError,
                                    phoneError: _registerPhoneError,
                                    passwordError: _registerPasswordError,
                                    confirmError: _registerConfirmError,
                                    formError: _registerFormError,
                                    onSubmit: _register,
                                    loading: _registerLoading,
                                    shakeAnimation: _registerShake,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LangStore.t('login.noAccount'),
                      style: const TextStyle(color: Color(0xFF6D7A72)),
                    ),
                    TextButton(
                      onPressed: () => _toggleMode(!_isLogin),
                      child: Text(
                        _isLogin
                            ? LangStore.t('login.signup')
                            : LangStore.t('signup.signIn'),
                        style: const TextStyle(
                          color: Color(0xFF2C9E6C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthModeToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const AuthModeToggle({
    super.key,
    required this.isLogin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pillWidth = (width - 8) / 2;
        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: pillWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(true),
                      child: Center(
                        child: Text(
                          LangStore.t('login.title'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isLogin
                                ? const Color(0xFF1F2A24)
                                : const Color(0xFF8A9690),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(false),
                      child: Center(
                        child: Text(
                          LangStore.t('signup.create'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !isLogin
                                ? const Color(0xFF1F2A24)
                                : const Color(0xFF8A9690),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final String? phoneError;
  final String? passwordError;
  final String? formError;
  final VoidCallback onSubmit;
  final bool loading;
  final Animation<double> shakeAnimation;

  const _LoginForm({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.phoneFocus,
    required this.passwordFocus,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.phoneError,
    required this.passwordError,
    required this.formError,
    required this.onSubmit,
    required this.loading,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      animation: shakeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedErrorText(message: formError),
          AnimatedInputField(
            label: LangStore.t('login.phone'),
            icon: Icons.phone_outlined,
            controller: phoneController,
            focusNode: phoneFocus,
            keyboardType: TextInputType.phone,
            errorText: phoneError,
          ),
          const SizedBox(height: 14),
          AnimatedInputField(
            label: LangStore.t('login.password'),
            icon: Icons.lock_outline,
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: true,
            errorText: passwordError,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: rememberMe
                      ? const Color(0xFF2C9E6C)
                      : const Color(0xFFE6ECE8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) => onRememberChanged(value ?? false),
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF2C9E6C),
                  side: const BorderSide(color: Colors.transparent),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                LangStore.t('login.remember'),
                style: const TextStyle(color: Color(0xFF6D7A72)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  LangStore.t('login.forgot'),
                  style: const TextStyle(color: Color(0xFF2C9E6C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedActionButton(
            label: LangStore.t('login.button'),
            onPressed: loading ? null : onSubmit,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final FocusNode emailFocus;
  final FocusNode phoneFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final String? firstNameError;
  final String? lastNameError;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final String? confirmError;
  final String? formError;
  final VoidCallback onSubmit;
  final bool loading;
  final Animation<double> shakeAnimation;

  const _RegisterForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmController,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.emailFocus,
    required this.phoneFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.firstNameError,
    required this.lastNameError,
    required this.emailError,
    required this.phoneError,
    required this.passwordError,
    required this.confirmError,
    required this.formError,
    required this.onSubmit,
    required this.loading,
    required this.shakeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      animation: shakeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedErrorText(message: formError),
          AnimatedInputField(
            label: LangStore.t('signup.firstName'),
            icon: Icons.person_outline,
            controller: firstNameController,
            focusNode: firstNameFocus,
            errorText: firstNameError,
          ),
          const SizedBox(height: 12),
          AnimatedInputField(
            label: LangStore.t('signup.lastName'),
            icon: Icons.person_outline,
            controller: lastNameController,
            focusNode: lastNameFocus,
            errorText: lastNameError,
          ),
          const SizedBox(height: 12),
          AnimatedInputField(
            label: LangStore.t('signup.email'),
            icon: Icons.email_outlined,
            controller: emailController,
            focusNode: emailFocus,
            keyboardType: TextInputType.emailAddress,
            errorText: emailError,
          ),
          const SizedBox(height: 12),
          AnimatedInputField(
            label: LangStore.t('signup.phone'),
            icon: Icons.phone_outlined,
            controller: phoneController,
            focusNode: phoneFocus,
            keyboardType: TextInputType.phone,
            errorText: phoneError,
          ),
          const SizedBox(height: 12),
          AnimatedInputField(
            label: LangStore.t('signup.password'),
            icon: Icons.lock_outline,
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: true,
            errorText: passwordError,
          ),
          const SizedBox(height: 12),
          AnimatedInputField(
            label: LangStore.t('signup.confirm'),
            icon: Icons.lock_outline,
            controller: confirmController,
            focusNode: confirmFocus,
            obscureText: true,
            errorText: confirmError,
          ),
          const SizedBox(height: 16),
          AnimatedActionButton(
            label: LangStore.t('signup.submit'),
            onPressed: loading ? null : onSubmit,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class AnimatedInputField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;

  const AnimatedInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final isFocused = focusNode.hasFocus;
        final hasError = errorText != null && errorText!.isNotEmpty;
        final borderColor = hasError
            ? const Color(0xFFE56A6A)
            : (isFocused ? const Color(0xFF2C9E6C) : const Color(0xFFE4E9E6));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2C9E6C).withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isFocused ? 1 : 0.6,
                    child: Icon(icon, color: borderColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: keyboardType,
                      obscureText: obscureText,
                      decoration: InputDecoration(
                        labelText: label,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        labelStyle: TextStyle(color: borderColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, top: 6),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFE56A6A),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AnimatedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final baseColor = enabled ? const Color(0xFF2C9E6C) : const Color(0xFFB8C6BF);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.7,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: _pressed ? 0.98 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered
                    ? baseColor.withOpacity(0.92)
                    : baseColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(_hovered ? 0.4 : 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedErrorText extends StatelessWidget {
  final String? message;

  const AnimatedErrorText({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null && message!.isNotEmpty;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: hasMessage
          ? Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2B4B4)),
              ),
              child: Text(
                message!,
                style: const TextStyle(color: Color(0xFFB24A4A)),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class ShakeWidget extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ShakeWidget({super.key, required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = animation.value;
        final dx = sin(progress * pi * 6) * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
