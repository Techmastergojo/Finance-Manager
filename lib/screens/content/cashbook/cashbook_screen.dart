import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class CashbookScreen extends StatefulWidget {
  final String khataId;
  final String khataName;
  final bool isSubPage;

  const CashbookScreen({
    super.key,
    this.khataId = 'main',
    this.khataName = 'Cashbook',
    this.isSubPage = false,
  });

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  final DatabaseService _db = DatabaseService();

  static const List<Map<String, dynamic>> _inCategories = [
    {'label': 'Sales', 'icon': Icons.storefront, 'key': 'sales'},
    {'label': 'Due Received', 'icon': Icons.payments, 'key': 'due_received'},
    {'label': 'Other Income', 'icon': Icons.add_circle, 'key': 'misc_in'},
  ];

  static const List<Map<String, dynamic>> _outCategories = [
    {'label': 'Expense', 'icon': Icons.shopping_cart, 'key': 'expense'},
    {'label': 'Salary', 'icon': Icons.badge, 'key': 'salary'},
    {'label': 'Purchase', 'icon': Icons.inventory, 'key': 'purchase'},
    {'label': 'Other', 'icon': Icons.remove_circle, 'key': 'misc_out'},
  ];

  void _showAddEntryDialog(String defaultType) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = defaultType;
    String selectedCategory = defaultType == 'in' ? 'sales' : 'expense';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setInner(() {
                        type = 'in';
                        selectedCategory = 'sales';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: type == 'in'
                              ? Colors.green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '💰 Cash In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: type == 'in'
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setInner(() {
                        type = 'out';
                        selectedCategory = 'expense';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: type == 'out'
                              ? Colors.red
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '💸 Cash Out',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: type == 'out'
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category chips
              Text('Category',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: (type == 'in' ? _inCategories : _outCategories)
                    .map((cat) => ChoiceChip(
                          label: Text(cat['label'] as String),
                          selected: selectedCategory == cat['key'],
                          onSelected: (_) =>
                              setInner(() => selectedCategory = cat['key'] as String),
                          selectedColor: type == 'in'
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Amount
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / Note',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setInner(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        type == 'in' ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Enter a valid amount')));
                      return;
                    }
                    await _db.addKhataEntry(
                      khataId: widget.khataId,
                      type: type,
                      amount: amount,
                      description: descCtrl.text.trim().isEmpty
                          ? selectedCategory
                          : descCtrl.text.trim(),
                      category: selectedCategory,
                      date: selectedDate,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Entry',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String key) {
    const map = {
      'sales': 'Sales',
      'due_received': 'Due Received',
      'misc_in': 'Other Income',
      'expense': 'Expense',
      'salary': 'Salary',
      'purchase': 'Purchase',
      'misc_out': 'Other',
    };
    return map[key] ?? key;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.khataName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _addBtn('+ In', Colors.green, () => _showAddEntryDialog('in')),
                    const SizedBox(width: 8),
                    _addBtn('- Out', Colors.red, () => _showAddEntryDialog('out')),
                  ],
                ),
              ],
            ),
          ),

          // Summary totals bar
          StreamBuilder<QuerySnapshot>(
            stream: _db.getKhataEntriesStream(widget.khataId),
            builder: (ctx, snap) {
              double totalIn = 0, totalOut = 0;
              if (snap.hasData) {
                for (var doc in snap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final amt = (d['amount'] ?? 0).toDouble();
                  if (d['type'] == 'in') {
                    totalIn += amt;
                  } else {
                    totalOut += amt;
                  }
                }
              }
              final net = totalIn - totalOut;
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: net >= 0
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: net >= 0
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _summaryCol('Cash In', 'Rs. ${totalIn.toStringAsFixed(0)}',
                        Colors.green),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _summaryCol('Cash Out',
                        'Rs. ${totalOut.toStringAsFixed(0)}', Colors.red),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _summaryCol(
                        'Net',
                        'Rs. ${net.toStringAsFixed(0)}',
                        net >= 0 ? Colors.green : Colors.red),
                  ],
                ),
              );
            },
          ),

          // Entries list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getKhataEntriesStream(widget.khataId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No entries yet',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('Tap + In or - Out to add',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final isIn = d['type'] == 'in';
                    final amount = (d['amount'] ?? 0).toDouble();
                    final ts = d['date'] as Timestamp?;
                    final date = ts?.toDate() ?? DateTime.now();

                    return Dismissible(
                      key: Key(docs[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Entry?'),
                                content: const Text(
                                    'This entry will be permanently deleted.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) =>
                          _db.deleteKhataEntry(widget.khataId, docs[i].id),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isIn
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isIn ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIn ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            d['description'] ?? _categoryLabel(d['category'] ?? ''),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${_categoryLabel(d['category'] ?? '')} • ${_formatDate(date)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Text(
                            '${isIn ? '+' : '-'} Rs. ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isIn ? Colors.green : Colors.red,
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
        ],
      ),
    );

    if (widget.isSubPage) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.khataName),
          centerTitle: true,
          elevation: 0,
        ),
        body: content,
      );
    }
    return content;
  }

  Widget _addBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}
