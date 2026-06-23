import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/screens/content/cashbook/cashbook_screen.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class KhataListScreen extends StatefulWidget {
  const KhataListScreen({super.key});

  @override
  State<KhataListScreen> createState() => _KhataListScreenState();
}

class _KhataListScreenState extends State<KhataListScreen> {
  final DatabaseService _db = DatabaseService();

  void _showCreateKhataDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Khata Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Ledger Name (e.g. Household, Business)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a ledger name')),
                );
                return;
              }
              await _db.createKhata(name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKhata(String khataId, String name) {
    if (khataId == 'main') return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Khata?'),
        content: Text('Are you sure you want to permanently delete "$name" and all its entries? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.deleteKhata(khataId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$name" deleted successfully'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildKhataCard({
    required String khataId,
    required String name,
    required bool isMain,
  }) {
    return StreamBuilder<Map<String, double>>(
      stream: _db.getKhataSummaryStream(khataId),
      builder: (context, snap) {
        final summary = snap.data ?? {'totalIn': 0.0, 'totalOut': 0.0, 'net': 0.0};
        final totalIn = summary['totalIn'] ?? 0.0;
        final totalOut = summary['totalOut'] ?? 0.0;
        final net = summary['net'] ?? 0.0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isMain ? Colors.blue.shade200 : Colors.grey.shade200,
              width: isMain ? 1.5 : 1,
            ),
          ),
          elevation: isMain ? 4 : 2,
          shadowColor: isMain ? Colors.blue.withOpacity(0.15) : Colors.black.withOpacity(0.05),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CashbookScreen(
                    khataId: khataId,
                    khataName: name,
                    isSubPage: true,
                  ),
                ),
              );
            },
            onLongPress: isMain ? null : () => _confirmDeleteKhata(khataId, name),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isMain ? Icons.star_rounded : Icons.folder_open_rounded,
                            color: isMain ? Colors.amber.shade700 : Colors.grey.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: isMain ? FontWeight.bold : FontWeight.w600,
                              color: isMain ? Colors.blue.shade900 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (isMain)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash In', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${totalIn.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Cash Out', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${totalOut.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Net Balance', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${net.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khata Ledgers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateKhataDialog,
        child: const Icon(Icons.create_new_folder_outlined, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Khatas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Long-press custom khata to delete',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.khatasStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customKhatas = snapshot.data?.docs ?? [];

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Always render the default Main Business Cashbook first
                      _buildKhataCard(
                        khataId: 'main',
                        name: 'Main Business Cashbook',
                        isMain: true,
                      ),
                      const SizedBox(height: 8),
                      if (customKhatas.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(),
                        ),
                        ...customKhatas.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unnamed Khata';
                          return _buildKhataCard(
                            khataId: doc.id,
                            name: name,
                            isMain: false,
                          );
                        }),
                      ],
                    ],
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
