import 'package:digital_khata/screens/auth/login_as_customer_screen.dart';
import 'package:digital_khata/screens/auth/login_screen.dart';
import 'package:digital_khata/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';

enum AuthPage { login, signup, customerLogin }

class ToggleLoginSignup extends StatefulWidget {
  const ToggleLoginSignup({super.key});

  @override
  State<ToggleLoginSignup> createState() => _ToggleLoginSignup();
}

class _ToggleLoginSignup extends State<ToggleLoginSignup> {
  AuthPage currentPage = AuthPage.login;

  void switchPage(AuthPage page) {
    setState(() {
      currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (currentPage) {
      case AuthPage.login:
        return LoginScreen(onTap: () => switchPage(AuthPage.signup));
      case AuthPage.signup:
        return SignupScreen(onTap: () => switchPage(AuthPage.login));
      case AuthPage.customerLogin:
        return LoginAsCustomerScreen(onTap: () => switchPage(AuthPage.login));
    }
  }
}
