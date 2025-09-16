import 'package:digital_khata/controller/toggle_login_signup.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController extends StatelessWidget {
  const AuthController({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen();
          } else {
            return const ToggleLoginSignup();
          }
        },
      ),
    );
  }
}
