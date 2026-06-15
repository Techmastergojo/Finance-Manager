import 'package:digital_khata/components/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// to display the message to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: ((context) {
      return AlertDialog(
        title: const Text("Notice"),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      );
    }),
  );
}

// Convert Firebase error codes into human-readable messages
String getFirebaseErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'The email address is not valid.';
    case 'user-disabled':
      return 'This user account has been disabled.';
    case 'user-not-found':
      return 'No user found with this email.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists for that email.';
    case 'operation-not-allowed':
      return 'Email/password accounts are not enabled.';
    case 'weak-password':
      return 'The password provided is too weak. Please use a stronger password.';
    case 'network-request-failed':
      return 'Network error. Please check your internet connection.';
    case 'unknown':
      // Often thrown when fields are empty or a generic error occurs
      return 'Please make sure all fields are filled out correctly, or check your internet connection.';
    default:
      return e.message ?? 'An unknown error occurred. Please try again.';
  }
}
void logout(BuildContext context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          MyButton(
            text: "Logout",
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      );
    },
  );
}
