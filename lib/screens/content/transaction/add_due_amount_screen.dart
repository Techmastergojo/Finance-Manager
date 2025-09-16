import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/components/my_text_field.dart';
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
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void dispose() {
    itemController.dispose();
    priceController.dispose();
    super.dispose();
  }

  // Add new due item to Firestore
  Future<void> addDueItem() async {
    final item = itemController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;

    if (item.isEmpty || price <= 0) return;

    await FirebaseFirestore.instance
        .collection('people')
        .doc(widget.personId)
        .collection('dueItems')
        .add({'item': item, 'price': price, 'time': Timestamp.now()});

    Navigator.pop(context); // Close popup
    itemController.clear();
    priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final itemsStream = FirebaseFirestore.instance
        .collection('people')
        .doc(widget.personId)
        .collection('dueItems')
        .orderBy('time', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(widget.personName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data?.docs ?? [];

          double totalAmount = 0;
          for (var item in items) {
            final data = item.data() as Map<String, dynamic>;
            totalAmount += (data['price'] ?? 0).toDouble();
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total Due: रू ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final data = items[index].data() as Map<String, dynamic>;
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
                            '\$${data['price'].toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
