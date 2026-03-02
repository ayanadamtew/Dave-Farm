import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/expense.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  
  List<Expense> _expenses = [];

  final List<String> _suggestions = [
    'Labor',
    'House Rent',
    'Vaccines',
    'Vitamins',
    'Veterinary Fees',
    'Feed',
    'Maintenance',
  ];

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
      category: _categoryCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await DatabaseHelper.instance.insertExpense(expense);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgSaved)),
      );
      _resetForm();
      Navigator.pop(context); // Close the sheet
      _loadExpenses(); // Refresh the list
    }
  }

  void _resetForm() {
    _amountCtrl.clear();
    _notesCtrl.clear();
    _categoryCtrl.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _categoryCtrl.dispose();
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
                      AppLocalizations.of(context)!.titleExpense,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _SectionLabel(AppLocalizations.of(context)!.labelCategoryType),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<String>.empty();
                        }
                        return _suggestions.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _categoryCtrl.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        // Sync the controllers
                        if (_categoryCtrl.text.isNotEmpty && controller.text.isEmpty) {
                          controller.text = _categoryCtrl.text;
                        }
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: '${AppLocalizations.of(context)!.categoryVaccines}, ${AppLocalizations.of(context)!.categoryLabor}, ${AppLocalizations.of(context)!.categoryFeed}',
                            prefixIcon: const Icon(Icons.category_rounded),
                          ),
                          validator: (value) => 
                            (value == null || value.trim().isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
                          onChanged: (val) => _categoryCtrl.text = val,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    _SectionLabel(AppLocalizations.of(context)!.fieldDate),
                    DatePickerTile(
                      label: AppLocalizations.of(context)!.fieldDate,
                      date: _selectedDate,
                      onChanged: (d) => setSheetState(() => _selectedDate = d),
                    ),
                    const Divider(height: 32),
      
                    _SectionLabel(AppLocalizations.of(context)!.fieldAmount),
                    const SizedBox(height: 12),
                    DecimalField(
                      label: AppLocalizations.of(context)!.fieldAmount,
                      controller: _amountCtrl,
                      prefixText: 'ETB ',
                    ),
                    const SizedBox(height: 20),
      
                    _SectionLabel(AppLocalizations.of(context)!.fieldNotes),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fieldNotes,
                        prefixIcon: const Padding(
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
                        label: Text(_isSaving ? AppLocalizations.of(context)!.msgSyncing : AppLocalizations.of(context)!.titleExpense),
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

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('labor')) return Icons.people_rounded;
    if (cat.contains('rent')) return Icons.home_rounded;
    if (cat.contains('vaccine') || cat.contains('medicine') || cat.contains('health')) {
      return Icons.medical_services_rounded;
    }
    if (cat.contains('vitamin')) return Icons.egg_rounded;
    if (cat.contains('vet') || cat.contains('doctor')) return Icons.local_hospital_rounded;
    if (cat.contains('feed')) return Icons.grass_rounded;
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('labor')) return Colors.blue;
    if (cat.contains('rent')) return Colors.orange;
    if (cat.contains('vaccine') || cat.contains('medicine') || cat.contains('health') || cat.contains('vet')) {
      return Colors.green;
    }
    if (cat.contains('feed')) return Colors.brown;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navExpenses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.labelAddExpense),
      ),
      body: _expenses.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.labelEmptyExpenses,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.labelEmptyExpensesSub,
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
              final categoryIcon = _getCategoryIcon(expense.category);
              final categoryColor = _getCategoryColor(expense.category);

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
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.category,
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
