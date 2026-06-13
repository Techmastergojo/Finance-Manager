import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Year', 'All Time'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: DateTime(weekStart.year, weekStart.month, weekStart.day),
            end: now);
      case 'This Month':
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: now);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default:
        return DateTimeRange(start: DateTime(2020), end: now);
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reports',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                // Backup status
                StreamBuilder<DocumentSnapshot>(
                  stream: _db.shopProfileStream,
                  builder: (ctx, snap) {
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '☁️ All data is automatically backed up to Firebase in real-time!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.green.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_done,
                                color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text('Backed Up',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _periods.map((p) {
                final selected = p == _selectedPeriod;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? primary
                              : Colors.grey.shade300),
                    ),
                    child: Text(p,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.grey.shade700,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            tabs: const [
              Tab(text: 'Khata Summary'),
              Tab(text: 'Cashbook'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KhataSummaryTab(db: _db, period: _getPeriodRange()),
                _CashbookSummaryTab(db: _db, period: _getPeriodRange()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Khata Summary Tab ───────────────────────────────────────────────────────

class _KhataSummaryTab extends StatelessWidget {
  final DatabaseService db;
  final DateTimeRange period;

  const _KhataSummaryTab({required this.db, required this.period});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.peopleStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No customers yet'));
        }

        final people = snap.data!.docs;

        return FutureBuilder<List<_PersonReport>>(
          future: _buildReports(people),
          builder: (ctx, reportSnap) {
            if (!reportSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final reports = reportSnap.data!;
            final totalOutstanding =
                reports.fold(0.0, (sum, r) => sum + r.netDue.clamp(0, double.infinity));
            final totalPeople = reports.length;
            final debtors = reports.where((r) => r.netDue > 0).toList()
              ..sort((a, b) => b.netDue.compareTo(a.netDue));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _reportCard(
                        'Total Outstanding',
                        'Rs. ${totalOutstanding.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _reportCard(
                        'Total Customers',
                        '$totalPeople',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _reportCard(
                        'With Balance',
                        '${debtors.length}',
                        Icons.warning_amber,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _reportCard(
                        'All Clear',
                        '${totalPeople - debtors.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (debtors.isNotEmpty) ...[
                  const Text('TOP DEBTORS',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  ...debtors.take(10).map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Text(
                              r.name.isNotEmpty
                                  ? r.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(r.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(r.phone),
                          trailing: Text(
                            'Rs. ${r.netDue.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_PersonReport>> _buildReports(
      List<QueryDocumentSnapshot> people) async {
    final List<_PersonReport> reports = [];
    for (var p in people) {
      final data = p.data() as Map<String, dynamic>;
      final netDue = await db.getTotalDue(p.id);
      reports.add(_PersonReport(
        id: p.id,
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
        netDue: netDue,
      ));
    }
    return reports;
  }

  Widget _reportCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _PersonReport {
  final String id, name, phone;
  final double netDue;
  _PersonReport(
      {required this.id,
      required this.name,
      required this.phone,
      required this.netDue});
}

// ─── Cashbook Summary Tab ─────────────────────────────────────────────────────

class _CashbookSummaryTab extends StatelessWidget {
  final DatabaseService db;
  final DateTimeRange period;

  const _CashbookSummaryTab({required this.db, required this.period});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.cashbookStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data['date'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();
          return date.isAfter(period.start) &&
              date.isBefore(period.end.add(const Duration(days: 1)));
        }).toList();

        double totalIn = 0, totalOut = 0;
        final Map<String, double> categoryTotals = {};

        for (var d in filtered) {
          final data = d.data() as Map<String, dynamic>;
          final amt = (data['amount'] ?? 0).toDouble();
          final cat = data['category'] ?? 'other';
          if (data['type'] == 'in') {
            totalIn += amt;
          } else {
            totalOut += amt;
          }
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
        }

        final net = totalIn - totalOut;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: net >= 0
                      ? [Colors.green.shade600, Colors.green.shade400]
                      : [Colors.red.shade600, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(net >= 0 ? 'NET PROFIT' : 'NET LOSS',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Rs. ${net.abs().toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(children: [
                        const Text('Cash In',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('Rs. ${totalIn.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                      Container(
                          width: 1, height: 30, color: Colors.white30),
                      Column(children: [
                        const Text('Cash Out',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('Rs. ${totalOut.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                      Container(
                          width: 1, height: 30, color: Colors.white30),
                      Column(children: [
                        const Text('Entries',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('${filtered.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),

            if (categoryTotals.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('BREAKDOWN BY CATEGORY',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: Colors.grey)),
              const SizedBox(height: 10),
              ...categoryTotals.entries.map((e) {
                final catLabel = _catLabel(e.key);
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(catLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    trailing: Text('Rs. ${e.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                );
              }),
            ],

            if (filtered.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No cashbook entries for this period',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        );
      },
    );
  }

  String _catLabel(String key) {
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
}
