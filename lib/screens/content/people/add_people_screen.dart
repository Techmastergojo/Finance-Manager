import 'dart:math';
import 'package:digital_khata/services/notification_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class AddPeopleScreen extends StatefulWidget {
  final String type; // 'due' or 'give'
  const AddPeopleScreen({super.key, this.type = 'due'});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  String _generateUniqueId() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select Due Date',
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final id = _generateUniqueId();
      final whatsappPhone = _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : _phoneController.text.trim();

      await DatabaseService().addPerson(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        id,
        dueDate: _selectedDueDate,
        whatsappPhone: whatsappPhone,
        type: widget.type,
      );

      if (_selectedDueDate != null) {
        await NotificationService().scheduleDueReminder(
          id: id.hashCode,
          personName: _nameController.text.trim(),
          amount: 0,
          dueDate: _selectedDueDate!,
          phone: whatsappPhone,
        );
      }

      if (mounted) {
        final entityName = widget.type == 'due' ? 'Customer' : 'Supplier';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_selectedDueDate != null
              ? '✅ $entityName added! Reminder set for ${_dueDateController.text}'
              : '✅ $entityName added successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDue = widget.type == 'due';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDue ? 'Add Customer' : 'Add Supplier'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Info', Icons.person, primary),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _dec(isDue ? 'Customer Name' : 'Supplier Name', Icons.person_outline),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                decoration: _dec('Phone Number', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 24),
              _section('Reminder (Optional)', Icons.notifications_active,
                  Colors.green.shade700),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsappController,
                decoration: _dec(
                  'WhatsApp Number',
                  Icons.chat_rounded,
                  hint: 'e.g. 923001234567 (with country code)',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 6),
              Text(
                'Include country code — 92 for Pakistan. Leave blank to use phone above.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: _dec(
                  'Payment Due Date',
                  Icons.calendar_today,
                  hint: 'Tap to pick a date',
                  suffixIcon: _selectedDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _selectedDueDate = null;
                            _dueDateController.clear();
                          }),
                        )
                      : null,
                ),
              ),
              if (_selectedDueDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'ll get a notification on this date with a WhatsApp reminder link.',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePerson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(isDue ? 'Add Customer' : 'Add Supplier',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      );

  InputDecoration _dec(String label, IconData icon,
      {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
