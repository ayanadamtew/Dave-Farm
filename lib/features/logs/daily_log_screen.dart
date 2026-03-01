import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/flock.dart';
import '../../shared/widgets/shared_widgets.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goodEggsCtrl = TextEditingController();
  final _brokenEggsCtrl = TextEditingController();
  final _deadBirdsCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<Flock> _flocks = [];
  Flock? _selectedFlock;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFlocks();
  }

  Future<void> _loadFlocks() async {
    final flocks = await DatabaseHelper.instance.getAllFlocks();
    if (mounted) setState(() => _flocks = flocks);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlock == null) {
      _showSnack('Please select a flock');
      return;
    }
    setState(() => _isSaving = true);

    final log = DailyLog.create(
      flockId: _selectedFlock!.id,
      date: _selectedDate,
      goodEggs: int.tryParse(_goodEggsCtrl.text) ?? 0,
      brokenEggs: int.tryParse(_brokenEggsCtrl.text) ?? 0,
      deadBirds: int.tryParse(_deadBirdsCtrl.text) ?? 0,
    );

    await DatabaseHelper.instance.insertDailyLog(log);

    if (mounted) {
      setState(() => _isSaving = false);
      _showSnack('Daily log saved!');
      _resetForm();
    }
  }

  void _resetForm() {
    _goodEggsCtrl.clear();
    _brokenEggsCtrl.clear();
    _deadBirdsCtrl.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedFlock = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _goodEggsCtrl.dispose();
    _brokenEggsCtrl.dispose();
    _deadBirdsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flock selector
              _SectionLabel('Select Flock'),
              const SizedBox(height: 8),
              if (_flocks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('No flocks found. Add a flock first.'),
                  ]),
                )
              else
                DropdownButtonFormField<Flock>(
                  value: _selectedFlock,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.group_rounded),
                  ),
                  hint: const Text('Choose flock'),
                  items: _flocks
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                              '${f.name} — ${f.currentBirdCount} birds',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (f) => setState(() => _selectedFlock = f),
                ),
              const SizedBox(height: 20),

              // Date picker
              _SectionLabel('Date'),
              DatePickerTile(
                label: 'Production Date',
                date: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const Divider(height: 32),

              // Egg counts
              _SectionLabel('Egg Count'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: NumpadField(
                    label: 'Good Eggs',
                    controller: _goodEggsCtrl,
                    prefixIcon: Icons.egg_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumpadField(
                    label: 'Broken',
                    controller: _brokenEggsCtrl,
                    prefixIcon: Icons.egg_alt_rounded,
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // Mortality
              _SectionLabel('Mortality'),
              const SizedBox(height: 12),
              NumpadField(
                label: 'Dead Birds',
                controller: _deadBirdsCtrl,
                prefixIcon: Icons.warning_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.amber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Entering dead birds will automatically update the flock\'s current count.',
                      style: TextStyle(fontSize: 11, color: Colors.amber),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving…' : 'Save Daily Log'),
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
