import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:digital_khata/screens/customer/customer_screen.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:flutter/material.dart';

class LoginAsCustomerScreen extends StatefulWidget {
  final void Function()? onTap;
  final void Function()? onregTap;
  const LoginAsCustomerScreen({
    super.key,
    required this.onTap,
    required this.onregTap,
  });

  @override
  State<LoginAsCustomerScreen> createState() => _LoginAsCustomerScreenState();
}

class _LoginAsCustomerScreenState extends State<LoginAsCustomerScreen> {
  //text controller
  final TextEditingController uniqueCodeController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  // Login customer
  Future<void> loginCustomer() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final uniqueId = uniqueCodeController.text.trim();
    
    if (uniqueId.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please enter your unique code';
      });
      return;
    }

    try {
      final customer = await CustomerService.findCustomerByUniqueId(uniqueId);
      
      if (customer != null) {
        // Navigate to customer screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerScreen(
              customerId: customer['id'],
              customerName: customer['name'] ?? 'Customer',
            ),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Invalid unique code. Please check and try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
                  height: 100,
                  width: 100,
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
                
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 15),

                //sign in button
                isLoading
                  ? const CircularProgressIndicator()
                  : MyButton(
                      text: "Login",
                      onTap: loginCustomer,
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