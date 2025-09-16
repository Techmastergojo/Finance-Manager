import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:flutter/material.dart';

class LoginAsCustomerScreen extends StatefulWidget {
  final void Function()? onTap;
  final void Function()? onregTap;
  const LoginAsCustomerScreen({super.key, required this.onTap, required this.onregTap});

  @override
  State<LoginAsCustomerScreen> createState() => _LoginAsCustomerScreenState();
}

class _LoginAsCustomerScreenState extends State<LoginAsCustomerScreen> {
  //text controller
  final TextEditingController uniqueCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              //logo image
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/digital-khata-logo.png',
                  height: 200,
                  width: 200,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),

                //
                Text(
                  'Digital Khata',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w200),
                ),

                const SizedBox(height: 25),
                // text fields for email and password
                MyTextField(
                  hintText: "Your Unique Code",
                  obscureText: false,
                  controller: uniqueCodeController,
                ),
                const SizedBox(height: 15),

                //sign in button
                MyButton(
                  text: "Login",
                  onTap: () {
                    // we will do here something...
                    // check the unique code is availabe in DB or not if not show error message if yes nav to user profile
                  },
                ),

                SizedBox(height: 15),

                //dont have an account? sign up
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onregTap,
                          child: Text(
                            ' Sign Up',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // spacing between the two lines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Already have an Account',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            ' Sign In',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
