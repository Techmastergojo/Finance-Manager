import 'package:digital_khata/components/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// to display the message to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: ((context) {
      return AlertDialog(
        title: Center(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
    }),
  );
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
