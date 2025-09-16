import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListPeopleScreen extends StatefulWidget {
  const ListPeopleScreen({super.key});

  @override
  State<ListPeopleScreen> createState() => _ListPeopleScreenState();
}

class _ListPeopleScreenState extends State<ListPeopleScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My People')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('people')
            .where('createdBy', isEqualTo: currentUser!.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No people found'));
          }

          final people = snapshot.data!.docs;

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final data = people[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(data['uniqueId'].toString().substring(0, 1)),
                ),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['phone'] ?? ''),
                trailing: Text(data['uniqueId'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
