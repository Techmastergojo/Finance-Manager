import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/screens/content/transaction/add_due_amount_screen.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class ListPeopleScreen extends StatefulWidget {
  const ListPeopleScreen({super.key});

  @override
  State<ListPeopleScreen> createState() => _ListPeopleScreenState();
}

class _ListPeopleScreenState extends State<ListPeopleScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    if (_authService.currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Scaffold(
        appBar: AppBar(title: const Text('My People')),
        body: StreamBuilder<QuerySnapshot>(
          stream: _databaseService.peopleStream,
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
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddDueAmountScreen(
                              personId: people[index].id,
                              personName: data['name'] ?? '',
                            ),
                          ),
                        );
                      },

                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,

                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Colors.primaries[data['name']
                                        .toString()
                                        .codeUnitAt(0) %
                                    Colors.primaries.length],
                            child: Text(
                              (data['name'] != null &&
                                      data['name'].toString().isNotEmpty)
                                  ? data['name']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          title: Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            data['phone'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['uniqueId'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
