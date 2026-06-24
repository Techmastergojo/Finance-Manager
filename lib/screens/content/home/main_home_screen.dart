import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/helper/helper_function.dart';
import 'package:digital_khata/screens/content/customer/khata_screen.dart';
import 'package:digital_khata/screens/content/settings/shop_profile_screen.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final peopleStream = _databaseService.peopleStream;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _databaseService.shopProfileStream,
              builder: (context, profileSnapshot) {
                String shopName = "Allah Tawakkal Traders";
                if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                   final data = profileSnapshot.data!.data() as Map<String, dynamic>;
                   shopName = data['shopName'] ?? "Allah Tawakkal Traders";
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.tertiary,
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context).colorScheme.primary,
                                  ],
                                  transform: GradientRotation(pi / 4),
                                ),
                              ),
                            ),
                            const Icon(Icons.storefront, color: Colors.white),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              Text(
                                shopName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSyncStatusIndicator(),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const ShopProfileScreen(),
                            ));
                          },
                          icon: const Icon(Icons.storefront_outlined),
                          tooltip: 'Shop Profile',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Summary Card (Total, Lowest, Highest)
            if (searchQuery.isEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: peopleStream,
                builder: (context, peopleSnapshot) {
                  if (!peopleSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final people = peopleSnapshot.data!.docs;

                  return FutureBuilder<Map<String, double>>(
                    future: _databaseService.getAllPeopleWithTotals(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final totals = snapshot.data ?? {};

                      double totalToReceive = 0;
                      double totalToGive = 0;

                      for (var person in people) {
                        final data = person.data() as Map<String, dynamic>;
                        final personId = person.id;
                        final type = data['type'] ?? 'due';
                        final personTotal = totals[personId] ?? 0;

                        if (type == 'due') {
                          if (personTotal > 0) {
                            totalToReceive += personTotal;
                          }
                        } else if (type == 'give') {
                          if (personTotal > 0) {
                            totalToGive += personTotal;
                          }
                        }
                      }

                      final netBalance = totalToReceive - totalToGive;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.tertiary,
                              Theme.of(context).colorScheme.secondary,
                              Theme.of(context).colorScheme.primary,
                            ],
                            transform: GradientRotation(pi / 4),
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade400,
                              blurRadius: 5,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Allah Tawakkal Traders Summary",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "To Receive",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Rs. ${totalToReceive.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 45,
                                  color: Colors.white30,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "To Give",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Rs. ${totalToGive.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                netBalance >= 0 
                                    ? "Net Balance (Get): Rs. ${netBalance.toStringAsFixed(0)}" 
                                    : "Net Balance (Give): Rs. ${netBalance.abs().toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 30),

            // All Peoples List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "All Peoples",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () => debugPrint("View All"),
                  child: Text(
                    "View All ▼",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: peopleStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final people = snapshot.data!.docs;

                  // Filter people based on search query
                  final filteredPeople = people.where((person) {
                    final data = person.data() as Map<String, dynamic>;
                    final name = data['name']?.toString().toLowerCase() ?? '';
                    final uniqueId =
                        data['uniqueId']?.toString().toLowerCase() ?? '';
                    return name.contains(searchQuery) ||
                        uniqueId.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredPeople.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredPeople[index].data() as Map<String, dynamic>;
                      final personId = filteredPeople[index].id;
                      final name = data['name'] ?? '';
                      final uniqueId = data['uniqueId'] ?? '';
                      final type = data['type'] ?? 'due';

                      return FutureBuilder<double>(
                        future: _databaseService.getTotalDue(personId),
                        builder: (context, snapshot) {
                          final totalDue = snapshot.data ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
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
                                    Colors.primaries[name.codeUnitAt(0) %
                                        Colors.primaries.length],
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: $uniqueId',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: type == 'due'
                                          ? Colors.blue.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type == 'due' ? 'Customer (To Receive)' : 'Supplier (To Give)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: type == 'due'
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${totalDue.abs().toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: totalDue <= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    totalDue == 0
                                        ? 'Clear'
                                        : totalDue < 0
                                            ? 'Advance'
                                            : 'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: totalDue <= 0
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KhataScreen(
                                      personId: personId,
                                      personName: name,
                                      personData: data,
                                      whatsappPhone: data['whatsappPhone'] as String? ?? '',
                                      phone: data['phone'] as String? ?? '',
                                      uniqueId: data['uniqueId'] as String? ?? '',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('people')
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Checking...',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final hasPending = snapshot.hasData ? snapshot.data!.metadata.hasPendingWrites : false;
        final isOnline = !hasPending;

        return Tooltip(
          message: isOnline
              ? 'All data is securely backed up to the cloud'
              : 'App is offline. Data is saved locally and will auto-sync when online',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOnline ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Cloud Synced' : 'Saving Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
