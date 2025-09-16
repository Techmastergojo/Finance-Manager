import 'package:flutter/material.dart';

// to display the message to user
void displayMessageToUser(String message, BuildContext context) {
  showDialog(context: context, builder: ((context) {
    return AlertDialog(
    
      title: Center(
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }));
}