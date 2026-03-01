import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/expense.dart';
import '../../shared/widgets/shared_widgets.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.labor;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final expense = Expense.create(
      date: _selectedDate,
      category: _selectedCategory,
      amount: double.parse(_amountCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await DatabaseHelper.instance.insertExpense(expense);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense logged!')),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    _amountCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategory.labor;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Category'),
              const SizedBox(height: 12),
              // Category chips
              Row(
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final label =
                      cat == ExpenseCategory.labor ? 'Labor' : 'House Rent';
                  final icon = cat == ExpenseCategory.labor
                      ? Icons.people_rounded
                      : Icons.home_rounded;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _selectedCategory = cat),
                          icon: Icon(icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white54),
                          label: Text(label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Date'),
              DatePickerTile(
                label: 'Expense Date',
                date: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const Divider(height: 32),

              _SectionLabel('Amount'),
              const SizedBox(height: 12),
              DecimalField(
                label: 'Amount',
                controller: _amountCtrl,
                prefixText: 'ETB ',
              ),
              const SizedBox(height: 20),

              _SectionLabel('Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.receipt_long_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Log Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ));
  }
}
