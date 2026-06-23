import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/screens/content/people/edit_customer_screen.dart';
import 'package:digital_khata/services/notification_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class KhataScreen extends StatefulWidget {
  final String personId;
  final String personName;
  final String? whatsappPhone;
  final String? phone;
  final String? uniqueId;
  final Map<String, dynamic> personData;

  const KhataScreen({
    super.key,
    required this.personId,
    required this.personName,
    required this.personData,
    this.whatsappPhone,
    this.phone,
    this.uniqueId,
  });

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _paymentDescController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    _paymentController.dispose();
    _paymentDescController.dispose();
    super.dispose();
  }

  String get _effectiveWaPhone =>
      (widget.whatsappPhone?.isNotEmpty == true
          ? widget.whatsappPhone!
          : widget.phone) ??
      '';

  bool get _isDueType => (widget.personData['type'] ?? 'due') == 'due';

  // ─── Add Due ────────────────────────────────────────────────────
  void _showAddDueDialog() {
    _itemController.clear();
    _priceController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isDueType ? 'Add Due Item' : 'Add Purchase / Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                  labelText: _isDueType ? 'Item / Description' : 'Bill / Purchase Item',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final item = _itemController.text.trim();
              final price =
                  double.tryParse(_priceController.text.trim()) ?? 0;
              if (item.isEmpty || price <= 0) return;
              await _db.addDueItem(widget.personId, item, price);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ─── Edit Due ───────────────────────────────────────────────────
  void _showEditDueDialog(String itemId, String currentItem, double currentPrice) {
    _itemController.text = currentItem;
    _priceController.text = currentPrice.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isDueType ? 'Edit Due Item' : 'Edit Purchase / Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                  labelText: _isDueType ? 'Item / Description' : 'Bill / Purchase Item',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final item = _itemController.text.trim();
              final price =
                  double.tryParse(_priceController.text.trim()) ?? 0;
              if (item.isEmpty || price <= 0) return;
              await _db.updateDueItem(widget.personId, itemId, item, price);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Record Payment ─────────────────────────────────────────────
  void _showPaymentDialog(double netDue) {
    _paymentController.clear();
    _paymentDescController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isDueType ? 'Record Received Payment' : 'Record Payment Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              netDue >= 0
                  ? (_isDueType ? 'Outstanding: Rs. ${netDue.toStringAsFixed(2)}' : 'We owe them: Rs. ${netDue.toStringAsFixed(2)}')
                  : (_isDueType ? 'Advance: Rs. ${(-netDue).toStringAsFixed(2)}' : 'Paid in advance: Rs. ${(-netDue).toStringAsFixed(2)}'),
              style: TextStyle(
                  color: netDue >= 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentController,
              decoration: InputDecoration(
                  labelText: _isDueType ? 'Amount Received (Rs.)' : 'Amount Paid (Rs.)',
                  border: const OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentDescController,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final amount =
                  double.tryParse(_paymentController.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Amount must be greater than 0'),
                  backgroundColor: Colors.orange,
                ));
                return;
              }
              final defaultDesc = _isDueType ? 'Payment received' : 'Payment paid';
              await _db.addPayment(
                  widget.personId, amount, _paymentDescController.text.trim().isEmpty ? defaultDesc : _paymentDescController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Record', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── WhatsApp Invoice ───────────────────────────────────────────
  Future<void> _sendWhatsAppInvoice(
    List<QueryDocumentSnapshot> dueItems,
    List<QueryDocumentSnapshot> payments,
    double totalDue,
    double totalPaid,
    double netDue,
    String shopName,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('🏪 *$shopName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(_isDueType ? '📋 *CUSTOMER KHATA / LEDGER*' : '📋 *SUPPLIER KHATA / LEDGER*');
    buffer.writeln(_isDueType ? '👤 Customer: *${widget.personName}*' : '👤 Supplier: *${widget.personName}*');
    if (widget.phone?.isNotEmpty == true) {
      buffer.writeln('📞 Phone: ${widget.phone}');
    }
    if (widget.uniqueId?.isNotEmpty == true) {
      buffer.writeln('🔑 ID: ${widget.uniqueId}');
    }
    final now = DateTime.now();
    buffer.writeln(
        '📅 Date: ${now.day}/${now.month}/${now.year}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');

    if (dueItems.isNotEmpty) {
      buffer.writeln(_isDueType ? '*ITEMS DUE (UDHAR):*' : '*BILLS / PURCHASES:*');
      for (var item in dueItems) {
        final d = item.data() as Map<String, dynamic>;
        buffer.writeln(
            '• ${d['item']} ......... Rs. ${d['price'].toStringAsFixed(0)}');
      }
      buffer.writeln();
    }

    if (payments.isNotEmpty) {
      buffer.writeln(_isDueType ? '*PAYMENTS RECEIVED:*' : '*PAYMENTS PAID:*');
      for (var p in payments) {
        final d = p.data() as Map<String, dynamic>;
        buffer.writeln(
            '✓ ${d['description']} ... Rs. ${d['amount'].toStringAsFixed(0)}');
      }
      buffer.writeln();
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(_isDueType
        ? '💳 Total Udhar: Rs. ${totalDue.toStringAsFixed(2)}'
        : '💳 Total Bills: Rs. ${totalDue.toStringAsFixed(2)}');
    buffer.writeln(_isDueType
        ? '✅ Total Paid:  Rs. ${totalPaid.toStringAsFixed(2)}'
        : '✅ Total Paid:  Rs. ${totalPaid.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln(netDue >= 0
        ? (_isDueType
            ? '🔴 *NET BALANCE (THEY OWE): Rs. ${netDue.toStringAsFixed(2)}*'
            : '🔴 *NET BALANCE (YOU OWE): Rs. ${netDue.toStringAsFixed(2)}*')
        : (_isDueType
            ? '🟢 *ADVANCE RECEIVED: Rs. ${(-netDue).toStringAsFixed(2)}*'
            : '🟢 *ADVANCE PAID: Rs. ${(-netDue).toStringAsFixed(2)}*'));
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━');
    if (_isDueType) {
      buffer.writeln('Meherbani karke jald se jald balance clear karein.');
    } else {
      buffer.writeln('Aap ka bacha hua payment jald clear kar diya jayega.');
    }
    buffer.writeln('Shukriya! 🙏');

    await openWhatsApp(
      phone: _effectiveWaPhone,
      personName: widget.personName,
      amount: netDue,
      customMessage: buffer.toString(),
    );
  }

  // ─── Delete Confirmation ────────────────────────────────────────
  Future<bool> _confirmDelete(BuildContext ctx, String msg) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personName),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: _isDueType ? 'Edit Customer' : 'Edit Supplier',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditCustomerScreen(
                  personId: widget.personId,
                  currentData: widget.personData,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getDueItemsStream(widget.personId),
        builder: (ctx, dueSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: _db.getPaymentsStream(widget.personId),
            builder: (ctx, paySnap) {
              final dueItems = dueSnap.data?.docs ?? [];
              final payments = paySnap.data?.docs ?? [];

              double totalDue = 0;
              for (var d in dueItems) {
                totalDue +=
                    ((d.data() as Map)['price'] ?? 0).toDouble();
              }
              double totalPaid = 0;
              for (var p in payments) {
                totalPaid +=
                    ((p.data() as Map)['amount'] ?? 0).toDouble();
              }
              final netDue = totalDue - totalPaid;

              // Build unified timeline
              final List<_KhataEntry> timeline = [
                ...dueItems.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = data['time'] as Timestamp?;
                  return _KhataEntry(
                    id: d.id,
                    type: 'due',
                    description: data['item'] ?? '',
                    amount: (data['price'] ?? 0).toDouble(),
                    time: ts?.toDate() ?? DateTime.now(),
                    raw: data,
                  );
                }),
                ...payments.map((p) {
                  final data = p.data() as Map<String, dynamic>;
                  final ts = data['time'] as Timestamp?;
                  return _KhataEntry(
                    id: p.id,
                    type: 'payment',
                    description: data['description'] ?? 'Payment',
                    amount: (data['amount'] ?? 0).toDouble(),
                    time: ts?.toDate() ?? DateTime.now(),
                    raw: data,
                  );
                }),
              ]..sort((a, b) => a.time.compareTo(b.time));

              // Calculate running balance
              double runningBalance = 0;
              final List<double> runningBalances = [];
              for (var entry in timeline) {
                if (entry.type == 'due') {
                  runningBalance += entry.amount;
                } else {
                  runningBalance -= entry.amount;
                }
                runningBalances.add(runningBalance);
              }

              return FutureBuilder<Map<String, dynamic>>(
                future: _db.getShopProfile(),
                builder: (ctx, shopSnap) {
                  final shopName =
                      shopSnap.data?['shopName'] ?? 'Allah Tawakkal Traders';

                  return Column(
                    children: [
                      // ─── Summary Card ──────────────────────────
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: netDue > 0
                                ? [
                                    Colors.red.shade600,
                                    Colors.red.shade400
                                  ]
                                : [
                                    Colors.green.shade600,
                                    Colors.green.shade400
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (netDue > 0 ? Colors.red : Colors.green)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              netDue > 0
                                  ? (_isDueType ? 'OUTSTANDING RECEIVABLE' : 'OUTSTANDING PAYABLE')
                                  : 'ALL CLEAR ✓',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${netDue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _statChip(_isDueType ? 'Udhar' : 'Bills',
                                    'Rs. ${totalDue.toStringAsFixed(0)}',
                                    Colors.red.shade100),
                                _statChip(_isDueType ? 'Paid' : 'Cleared',
                                    'Rs. ${totalPaid.toStringAsFixed(0)}',
                                    Colors.green.shade100),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ─── Action Buttons ────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  elevation: 0,
                                  side: BorderSide(
                                      color: Colors.red.shade200),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add),
                                label: Text(_isDueType ? 'Add Due' : 'Add Bill'),
                                onPressed: _showAddDueDialog,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.shade50,
                                  foregroundColor:
                                      Colors.green.shade700,
                                  elevation: 0,
                                  side: BorderSide(
                                      color: Colors.green.shade200),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.payments),
                                label: Text(_isDueType ? 'Payment' : 'Pay Out'),
                                onPressed: () =>
                                    _showPaymentDialog(netDue),
                              ),
                            ),
                            if (_effectiveWaPhone.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.receipt_long,
                                    size: 18),
                                label: const Text('Invoice'),
                                onPressed: () => _sendWhatsAppInvoice(
                                    dueItems,
                                    payments,
                                    totalDue,
                                    totalPaid,
                                    netDue,
                                    shopName),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ─── Khata Header ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Text('KHATA',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: Colors.grey)),
                            const Spacer(),
                            Text(
                                '${timeline.length} entries',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),

                      // ─── Timeline List ─────────────────────────
                      Expanded(
                        child: timeline.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.book_outlined,
                                        size: 60, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text('No transactions yet',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16)),
                                    SizedBox(height: 4),
                                    Text('Tap "Add Due" to start',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                itemCount: timeline.length,
                                itemBuilder: (ctx, i) {
                                  final entry = timeline[i];
                                  final isLast = i == timeline.length - 1;
                                  final isDue = entry.type == 'due';
                                  final bal = runningBalances[i];

                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Timeline line
                                        SizedBox(
                                          width: 32,
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: isDue
                                                      ? Colors.red
                                                      : Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              if (!isLast)
                                                Expanded(
                                                  child: Container(
                                                    width: 2,
                                                    color:
                                                        Colors.grey.shade300,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Entry card
                                        Expanded(
                                          child: GestureDetector(
                                            onLongPress: () async {
                                              final action =
                                                  await _showEntryOptions(
                                                      ctx, entry, isDue);
                                              if (action == 'edit' &&
                                                  isDue) {
                                                _showEditDueDialog(
                                                    entry.id,
                                                    entry.description,
                                                    entry.amount);
                                              } else if (action ==
                                                  'delete') {
                                                final confirm =
                                                    await _confirmDelete(
                                                  context,
                                                  'Delete this ${isDue ? "due item" : "payment"}?',
                                                );
                                                if (confirm) {
                                                  if (isDue) {
                                                    await _db.deleteDueItem(
                                                        widget.personId,
                                                        entry.id);
                                                  } else {
                                                    await _db.deletePayment(
                                                        widget.personId,
                                                        entry.id);
                                                  }
                                                }
                                              }
                                            },
                                            child: Card(
                                              margin: const EdgeInsets.only(
                                                  left: 8, bottom: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10),
                                                side: BorderSide(
                                                  color: isDue
                                                      ? Colors.red.shade100
                                                      : Colors.green
                                                          .shade100,
                                                  width: 1,
                                                ),
                                              ),
                                              elevation: 1,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(
                                                        10),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            entry.description,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize:
                                                                    14),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            _formatDate(
                                                                entry.time),
                                                            style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          isDue
                                                              ? '+ Rs. ${entry.amount.toStringAsFixed(0)}'
                                                              : '- Rs. ${entry.amount.toStringAsFixed(0)}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                            color: isDue
                                                                ? Colors.red
                                                                : Colors
                                                                    .green,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          'Bal: Rs. ${bal.toStringAsFixed(0)}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: bal > 0
                                                                ? Colors.red
                                                                    .shade400
                                                                : Colors
                                                                    .green
                                                                    .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _showEntryOptions(
      BuildContext ctx, _KhataEntry entry, bool isDue) async {
    return showModalBottomSheet<String>(
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
            if (isDue)
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Due Item'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: bg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _KhataEntry {
  final String id;
  final String type; // 'due' or 'payment'
  final String description;
  final double amount;
  final DateTime time;
  final Map<String, dynamic> raw;

  _KhataEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.time,
    required this.raw,
  });
}
