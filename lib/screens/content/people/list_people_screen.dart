import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/screens/content/customer/khata_screen.dart';
import 'package:digital_khata/screens/content/people/edit_customer_screen.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class ListPeopleScreen extends StatefulWidget {
  const ListPeopleScreen({super.key});

  @override
  State<ListPeopleScreen> createState() => _ListPeopleScreenState();
}

class _ListPeopleScreenState extends State<ListPeopleScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _confirmDeletePerson(
      String personId, String personName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'This will permanently delete $personName and all their transaction history.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deletePerson(personId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$personName deleted'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customers',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                  'Long-press to edit/delete',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.peopleStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No customers yet',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Tap + to add your first customer',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final people = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final doc = people[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final personId = doc.id;
                    final name = data['name'] ?? '';
                    final phone = data['phone'] ?? '';

                    final avatarColor = Colors.primaries[
                        name.isNotEmpty
                            ? name.codeUnitAt(0) % Colors.primaries.length
                            : 0];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KhataScreen(
                              personId: personId,
                              personName: name,
                              personData: data,
                              whatsappPhone:
                                  data['whatsappPhone'] as String? ?? '',
                              phone: phone,
                              uniqueId:
                                  data['uniqueId'] as String? ?? '',
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _showOptions(context, personId, name, data),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: avatarColor,
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          subtitle: Text(phone,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['uniqueId'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                      fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext ctx, String personId, String name,
      Map<String, dynamic> data) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Customer'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => EditCustomerScreen(
                      personId: personId,
                      currentData: data,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Customer',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeletePerson(personId, name);
              },
            ),
          ],
        ),
      ),
    );
  }
}
