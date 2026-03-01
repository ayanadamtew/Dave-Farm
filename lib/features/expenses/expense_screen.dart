import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/expense.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

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
  
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }
  
  Future<void> _loadExpenses() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _expenses.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

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
      Navigator.pop(context); // Close the sheet
      _loadExpenses(); // Refresh the list
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
  
  void _openAddExpenseSheet() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Expense',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Category'),
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
                                    setSheetState(() => _selectedCategory = cat),
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
      
                    const _SectionLabel('Date'),
                    DatePickerTile(
                      label: 'Expense Date',
                      date: _selectedDate,
                      onChanged: (d) => setSheetState(() => _selectedDate = d),
                    ),
                    const Divider(height: 32),
      
                    const _SectionLabel('Amount'),
                    const SizedBox(height: 12),
                    DecimalField(
                      label: 'Amount',
                      controller: _amountCtrl,
                      prefixText: 'ETB ',
                    ),
                    const SizedBox(height: 20),
      
                    const _SectionLabel('Notes (Optional)'),
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
      
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isSaving ? null : () {
                          setSheetState(() => _isSaving = true);
                          _save().whenComplete(() {
                            if (mounted) setSheetState(() => _isSaving = false);
                          });
                        },
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
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: _expenses.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No Expenses Logged',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to record an expense',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: expense.category == ExpenseCategory.labor 
                            ? Colors.blue.withOpacity(0.15) 
                            : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          expense.category == ExpenseCategory.labor 
                            ? Icons.people_rounded 
                            : Icons.home_rounded,
                          color: expense.category == ExpenseCategory.labor 
                            ? Colors.blue 
                            : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.category == ExpenseCategory.labor ? 'Labor' : 'House Rent',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(expense.date),
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                expense.notes!,
                                style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      ),
                      Text(
                        'ETB ${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
