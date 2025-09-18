import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/services/customer_service.dart';
import 'package:flutter/material.dart';

class CustomerScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  Map<String, double> totals = {'totalDue': 0, 'totalPaid': 0, 'netDue': 0};

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    final customerTotals = await CustomerService.getCustomerTotals(
      widget.customerId,
    );
    setState(() {
      totals = customerTotals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dueItemsStream = CustomerService.getDueItemsStream(widget.customerId);
    final paymentsStream = CustomerService.getPaymentsStream(widget.customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Due:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'रू ${totals['totalDue']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Paid:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'रू ${totals['totalPaid']!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net Due:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'रू ${totals['netDue']!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: totals['netDue']! > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Due Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: dueItemsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No due items found'));
                  }

                  final dueItems = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: dueItems.length,
                    itemBuilder: (context, index) {
                      final data =
                          dueItems[index].data() as Map<String, dynamic>;
                      final time = (data['time'] as Timestamp).toDate();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(data['item'] ?? 'Unknown Item'),
                          subtitle: Text(
                            '${time.day}/${time.month}/${time.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            'रू ${data['price'].toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment History:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: paymentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No payment history found'),
                    );
                  }

                  final payments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final data =
                          payments[index].data() as Map<String, dynamic>;
                      final time = (data['time'] as Timestamp).toDate();
                      final description = data['description'] ?? 'Payment';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.green.shade50,
                        child: ListTile(
                          title: Text(description),
                          subtitle: Text(
                            '${time.day}/${time.month}/${time.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            'रू ${data['amount'].toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
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
      ),
    );
  }
}
