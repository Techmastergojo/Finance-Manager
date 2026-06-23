import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/screens/content/customer/khata_screen.dart';
import 'package:digital_khata/screens/content/people/add_people_screen.dart';
import 'package:digital_khata/screens/content/people/edit_customer_screen.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Re-build to update action button type
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeletePerson(String personId, String personName, String type) async {
    final entityName = type == 'due' ? 'Customer' : 'Supplier';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $entityName?'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

  void _showOptions(BuildContext ctx, String personId, String name, String type, Map<String, dynamic> data) {
    final entityName = type == 'due' ? 'Customer' : 'Supplier';
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit $entityName'),
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
              title: Text('Delete $entityName', style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeletePerson(personId, name, type);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.peopleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPeople = snapshot.data?.docs ?? [];
        // Filter by type ('due' or 'give') and search query
        final filteredPeople = allPeople.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docType = data['type'] ?? 'due';
          final name = (data['name'] ?? '').toString().toLowerCase();
          final phone = (data['phone'] ?? '').toString();
          final matchType = docType == type;
          final matchSearch = name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery);
          return matchType && matchSearch;
        }).toList();

        if (filteredPeople.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type == 'due' ? Icons.people_outline : Icons.local_shipping_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  type == 'due' ? 'No receivables yet' : 'No payables yet',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  type == 'due'
                      ? 'Tap + to add a customer who owes you money'
                      : 'Tap + to add a supplier you owe money to',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredPeople.length,
          itemBuilder: (context, index) {
            final doc = filteredPeople[index];
            final data = doc.data() as Map<String, dynamic>;
            final personId = doc.id;
            final name = data['name'] ?? '';
            final phone = data['phone'] ?? '';

            final avatarColor = Colors.primaries[
                name.isNotEmpty ? name.codeUnitAt(0) % Colors.primaries.length : 0];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KhataScreen(
                      personId: personId,
                      personName: name,
                      personData: data,
                      whatsappPhone: data['whatsappPhone'] as String? ?? '',
                      phone: phone,
                      uniqueId: data['uniqueId'] as String? ?? '',
                    ),
                  ),
                );
              },
              onLongPress: () => _showOptions(context, personId, name, type, data),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor.withOpacity(0.85),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(phone.isNotEmpty ? phone : 'No phone number', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  trailing: FutureBuilder<double>(
                    future: _db.getTotalDue(personId),
                    builder: (context, balanceSnap) {
                      final balance = balanceSnap.data ?? 0.0;
                      final showGreen = (type == 'due' && balance <= 0) || (type == 'give' && balance <= 0);
                      final displayBalance = balance.abs();

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${displayBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: showGreen ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                balance == 0
                                    ? 'Clear'
                                    : balance < 0
                                        ? 'Advance'
                                        : 'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: showGreen ? Colors.green.shade600 : Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Payment Due'),
            Tab(text: 'Payment to Give'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final activeType = _tabController.index == 0 ? 'due' : 'give';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPeopleScreen(type: activeType),
            ),
          );
        },
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: _tabController.index == 0 ? 'Search customers...' : 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPeopleList('due'),
                _buildPeopleList('give'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
