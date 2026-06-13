import 'dart:math';
import 'package:digital_khata/components/my_button.dart';
import 'package:digital_khata/services/notification_service.dart';
import 'package:digital_khata/services/services.dart';
import 'package:flutter/material.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
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

  String generateUniqueId() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
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

  Future<void> savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final id = generateUniqueId();
      final db = DatabaseService();

      await db.addPerson(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        id,
        dueDate: _selectedDueDate,
        whatsappPhone: _whatsappController.text.trim(),
      );

      // Schedule a notification if due date was set
      if (_selectedDueDate != null) {
        final whatsappPhone = _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : _phoneController.text.trim();

        await NotificationService().scheduleDueReminder(
          id: id.hashCode,
          personName: _nameController.text.trim(),
          amount: 0, // Will be updated when dues are added
          dueDate: _selectedDueDate!,
          phone: whatsappPhone,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedDueDate != null
                  ? '✅ Person added! Reminder set for ${_dueDateController.text}'
                  : '✅ Person added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add person: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Person'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              _sectionHeader('Basic Information', Icons.person, primary),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                maxLength: 15,
                controller: _phoneController,
                decoration:
                    _inputDecoration('Phone Number', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter phone number' : null,
              ),

              const SizedBox(height: 8),

              // WhatsApp + Due Date Section
              _sectionHeader(
                  'Payment Reminder (Optional)', Icons.notifications_active, Colors.green),
              const SizedBox(height: 12),

              // WhatsApp number field
              TextFormField(
                controller: _whatsappController,
                decoration: _inputDecoration(
                  'WhatsApp Number (with country code)',
                  Icons.chat,
                  hint: 'e.g. 923001234567',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Include country code (92 for Pakistan). Leave blank to use phone number above.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Due Date picker
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: _pickDueDate,
                decoration: _inputDecoration(
                  'Due Date (when to remind you)',
                  Icons.calendar_today,
                  hint: 'Tap to pick a date',
                  suffixIcon: _selectedDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                              _dueDateController.clear();
                            });
                          },
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
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will get a notification on ${_dueDateController.text} with a WhatsApp link to send a reminder message.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : MyButton(text: 'Add Person', onTap: savePerson),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
    Widget? suffixIcon,
  }) {
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
