import 'package:digital_khata/controller/auth.dart';
import 'package:digital_khata/controller/toggle_login_signup.dart';
import 'package:digital_khata/screens/content/home/home_screen.dart';
import 'package:digital_khata/screens/content/people/list_people_screen.dart';
import 'package:flutter/material.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Digital Khata",
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade100,
          onSurface: Colors.black,
          primary: Color(0xFF4A90E2),
          secondary: Color(0xFF1ABC9C),
          tertiary: Color(0xFFBDC3C7),
          outline: Colors.grey,
        ),
      ),

      home: AuthController(),
      routes: {
        '/toggle_login_signup_screen': (context) => const ToggleLoginSignup(),
        '/home_screen': (context) => HomeScreen(),
        // '/profile_page': (context) => ProfilePage(),
        '/list_people_screen': (context) => ListPeopleScreen(),
      },
    );
  }
}
