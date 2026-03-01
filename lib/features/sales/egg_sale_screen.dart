import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/egg_sale.dart';
import '../../shared/widgets/shared_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _quantityCtrl.addListener(_recalcTotal);
    _unitPriceCtrl.addListener(_recalcTotal);
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
        const SnackBar(content: Text('Sale recorded!')),
      );
      _resetForm();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Egg Sale')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Customer'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _customerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Date'),
              DatePickerTile(
                label: 'Sale Date',
                date: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const Divider(height: 32),

              _SectionLabel('Sale Details'),
              const SizedBox(height: 12),
              NumpadField(
                label: 'Quantity (eggs)',
                controller: _quantityCtrl,
                prefixIcon: Icons.egg_rounded,
              ),
              const SizedBox(height: 16),
              DecimalField(
                label: 'Unit Price',
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 1)),
                        Text('Auto-calculated',
                            style: TextStyle(
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

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sell_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Record Sale'),
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
