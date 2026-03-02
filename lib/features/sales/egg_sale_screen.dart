import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/egg_sale.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

class EggSaleScreen extends StatefulWidget {
  const EggSaleScreen({super.key});

  @override
  State<EggSaleScreen> createState() => _EggSaleScreenState();
}

class _EggSaleScreenState extends State<EggSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '0.00');

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  
  List<EggSale> _sales = [];

  @override
  void initState() {
    super.initState();
    _quantityCtrl.addListener(_recalcTotal);
    _unitPriceCtrl.addListener(_recalcTotal);
    _loadSales();
  }
  
  Future<void> _loadSales() async {
    final sales = await DatabaseHelper.instance.getAllEggSales();
    if (mounted) {
      setState(() {
        _sales = sales;
        _sales.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  void _recalcTotal() {
    final qty = int.tryParse(_quantityCtrl.text) ?? 0;
    final unit = double.tryParse(_unitPriceCtrl.text) ?? 0.0;
    final total = qty * unit;
    _totalCtrl.text = total.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final sale = EggSale.create(
      customerName: _customerCtrl.text.trim(),
      date: _selectedDate,
      quantity: int.parse(_quantityCtrl.text),
      unitPrice: double.parse(_unitPriceCtrl.text),
    );

    await DatabaseHelper.instance.insertEggSale(sale);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.msgSaved)),
      );
      _resetForm();
      Navigator.pop(context);
      _loadSales();
    }
  }

  void _resetForm() {
    _customerCtrl.clear();
    _quantityCtrl.clear();
    _unitPriceCtrl.clear();
    _totalCtrl.text = '0.00';
    setState(() => _selectedDate = DateTime.now());
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _quantityCtrl.dispose();
    _unitPriceCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }
  
  void _openAddSaleSheet() {
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
                      AppLocalizations.of(context)!.labelNewSale,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(AppLocalizations.of(context)!.labelCustomer),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customerCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fieldCustomerName,
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
                    ),
                    const SizedBox(height: 20),
      
                    _SectionLabel(AppLocalizations.of(context)!.fieldDate),
                    DatePickerTile(
                      label: AppLocalizations.of(context)!.fieldDate,
                      date: _selectedDate,
                      onChanged: (d) => setSheetState(() => _selectedDate = d),
                    ),
                    const Divider(height: 32),
      
                    _SectionLabel(AppLocalizations.of(context)!.labelSaleDetails),
                    const SizedBox(height: 12),
                    NumpadField(
                      label: AppLocalizations.of(context)!.fieldQuantity,
                      controller: _quantityCtrl,
                      prefixIcon: Icons.egg_rounded,
                    ),
                    const SizedBox(height: 16),
                    DecimalField(
                      label: AppLocalizations.of(context)!.fieldUnitPrice,
                      controller: _unitPriceCtrl,
                      prefixText: 'ETB ',
                    ),
                    const SizedBox(height: 16),
      
                    // Auto-calculated total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context)!.fieldTotalPrice.toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                      letterSpacing: 1)),
                              Text(AppLocalizations.of(context)!.labelTotalCalculated,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: _totalCtrl,
                            builder: (_, v, __) => Text(
                              'ETB ${_totalCtrl.text}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF66BB6A),
                              ),
                            ),
                          ),
                        ],
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
                             : const Icon(Icons.sell_rounded),
                        label: Text(_isSaving ? AppLocalizations.of(context)!.msgSyncing : AppLocalizations.of(context)!.titleEggSale),
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navSales)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSaleSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.labelAddSale),
      ),
      body: _sales.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.point_of_sale_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.labelEmptySales,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.labelEmptySalesSub,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _sales.length,
            itemBuilder: (context, index) {
              final sale = _sales[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sale.customerName ?? AppLocalizations.of(context)!.labelCustomer,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(sale.date),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                               const Icon(Icons.egg_rounded, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('${sale.quantity} ${AppLocalizations.of(context)!.fieldGoodEggs.toLowerCase()} @ ${sale.unitPrice}'),
                            ],
                          ),
                          Text(
                            'ETB ${sale.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF66BB6A),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
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
