import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class AddDueAmountScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const AddDueAmountScreen({
    super.key,
    required this.personId,
    required this.personName,
  });

  @override
  State<AddDueAmountScreen> createState() => _AddDueAmountScreenState();
}

class _AddDueAmountScreenState extends State<AddDueAmountScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController paymentDescriptionController =
      TextEditingController();

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    paymentController.dispose();
    paymentDescriptionController.dispose();
    super.dispose();
  }

  // Add new due item to Firestore
  Future<void> addDueItem() async {
    final item = itemController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;

    if (item.isEmpty || price <= 0) return;

    await _databaseService.addDueItem(widget.personId, item, price);

    Navigator.pop(context);
    itemController.clear();
    priceController.clear();
    setState(() {});
  }

  // Add payment to clear due
  Future<void> addPayment() async {
    final amount = double.tryParse(paymentController.text.trim()) ?? 0;
    final description = paymentDescriptionController.text.trim();

    // Get the net due amount
    final dueItemsStream = _databaseService.getDueItemsStream(widget.personId);
    final paymentsStream = _databaseService.getPaymentsStream(widget.personId);

    final dueSnapshot = await dueItemsStream.first;
    final paymentSnapshot = await paymentsStream.first;

    double totalDueAmount = 0;
    for (var item in dueSnapshot.docs) {
      final data = item.data() as Map<String, dynamic>;
      totalDueAmount += (data['price'] ?? 0).toDouble();
    }

    double totalPaidAmount = 0;
    for (var payment in paymentSnapshot.docs) {
      final data = payment.data() as Map<String, dynamic>;
      totalPaidAmount += (data['amount'] ?? 0).toDouble();
    }

    final netDue = totalDueAmount - totalPaidAmount;

    // Prevent payment if it exceeds the net due
    if (amount <= 0 || amount > netDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cannot exceed the due amount')),
      );
      return;
    }

    // Proceed with adding the payment to Firestore
    await _databaseService.addPayment(widget.personId, amount, description);

    Navigator.pop(context);
    paymentController.clear();
    paymentDescriptionController.clear();
    setState(() {});
  }

  // Show payment dialog
  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Due'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: paymentController,
              decoration: const InputDecoration(labelText: 'Amount to Clear'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          MyButton(text: "Clear Due", onTap: addPayment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueItemsStream = _databaseService.getDueItemsStream(widget.personId);
    final paymentsStream = _databaseService.getPaymentsStream(widget.personId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.personName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: dueItemsStream,
        builder: (context, dueSnapshot) {
          if (dueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final dueItems = dueSnapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: paymentsStream,
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final payments = paymentSnapshot.data?.docs ?? [];

              double totalDueAmount = 0;
              for (var item in dueItems) {
                final data = item.data() as Map<String, dynamic>;
                totalDueAmount += (data['price'] ?? 0).toDouble();
              }

              double totalPaidAmount = 0;
              for (var payment in payments) {
                final data = payment.data() as Map<String, dynamic>;
                totalPaidAmount += (data['amount'] ?? 0).toDouble();
              }

              final netDue = totalDueAmount - totalPaidAmount;

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Summary card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: netDue > 0
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Due: रू ${totalDueAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Paid: रू ${totalPaidAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Net Due: रू ${netDue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: netDue > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Clear Due button
                    if (netDue > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MyButton(
                          text: "Clear Due",
                          onTap: _showPaymentDialog,
                        ),
                      ),

                    // Transactions list
                    Expanded(
                      child: ListView(
                        children: [
                          // Due Items
                          if (dueItems.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Due Items",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...dueItems.map((item) {
                              final data = item.data() as Map<String, dynamic>;
                              final time = (data['time'] as Timestamp).toDate();

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(data['item'] ?? ''),
                                  subtitle: Text(
                                    '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
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
                            }).toList(),
                          ],

                          // Payments
                          if (payments.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "Payments",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            ...payments.map((payment) {
                              final data =
                                  payment.data() as Map<String, dynamic>;
                              final time = (data['time'] as Timestamp).toDate();
                              final description =
                                  data['description'] ?? 'Payment';

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(description),
                                  subtitle: Text(
                                    '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
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
                            }).toList(),
                          ],

                          if (dueItems.isEmpty && payments.isEmpty)
                            const Center(child: Text('No transactions yet')),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Due Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextField(
                    controller: itemController,
                    hintText: 'Items Name',
                    obscureText: false,
                  ),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date & Time: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                MyButton(text: "Add", onTap: addDueItem),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
