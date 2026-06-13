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
  final AuthService _authService = AuthService();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (_authService.currentUser == null) {
      return const Scaffold(body: Center(child: Text("No user logged in")));
    }

    final peopleStream = _databaseService.peopleStream;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            // Top row with welcome and logout
            Row(
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
                        const Icon(Icons.person, color: Colors.white),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome,",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          Text(
                            _authService.currentUser!.email ?? "User",
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
                IconButton(
                  onPressed: () {
                    logout(context);
                  },
                  icon: const Icon(Icons.logout_outlined),
                ),
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

                      double totalDue = 0;
                      double lowestDue = double.infinity;
                      double highestDue = 0;
                      String lowestPerson = '';
                      String highestPerson = '';

                      for (var person in people) {
                        final data = person.data() as Map<String, dynamic>;
                        final name = data['name'] ?? '';
                        final personId = person.id;
                        final personTotal = totals[personId] ?? 0;

                        totalDue += personTotal;

                        if (personTotal < lowestDue) {
                          lowestDue = personTotal;
                          lowestPerson = name;
                        }

                        if (personTotal > highestDue) {
                          highestDue = personTotal;
                          highestPerson = name;
                        }
                      }

                      return Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width / 2,
                        padding: const EdgeInsets.all(16),
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
                              "Total Due Amount",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Rs. ${totalDue.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Lowest Due / Person",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      "Rs. ${lowestDue.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      lowestPerson,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Highest Due / Person",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      "Rs. ${highestDue.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      highestPerson,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                              subtitle: Text(
                                'ID: $uniqueId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Text(
                                'Rs. ${totalDue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: totalDue > 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 16,
                                ),
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
}
