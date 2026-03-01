import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/flock.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';

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
  
  List<DailyLog> _logs = [];
  Map<String, String> _flockNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final flocks = await DatabaseHelper.instance.getAllFlocks();
    final logs = await DatabaseHelper.instance.getAllDailyLogs();
    
    final names = <String, String>{};
    for (var f in flocks) {
      names[f.id] = f.name;
    }
    
    if (mounted) {
      setState(() {
        _flocks = flocks;
        _logs = logs;
        _flockNames = names;
        // Sort logs descending by date
        _logs.sort((a, b) => b.date.compareTo(a.date));
      });
    }
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
      Navigator.pop(context); // Close the modal sheet
      _loadData(); // Refresh the list
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
  
  void _openAddLogSheet() {
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
                      'New Daily Log',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Flock selector
                    const _SectionLabel('Select Flock'),
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
                        onChanged: (f) => setSheetState(() => _selectedFlock = f),
                      ),
                    const SizedBox(height: 20),
      
                    // Date picker
                    const _SectionLabel('Date'),
                    DatePickerTile(
                      label: 'Production Date',
                      date: _selectedDate,
                      onChanged: (d) => setSheetState(() => _selectedDate = d),
                    ),
                    const Divider(height: 32),
      
                    // Egg counts
                    const _SectionLabel('Egg Count'),
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
                    const _SectionLabel('Mortality'),
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
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? 'Saving…' : 'Save Daily Log'),
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
      appBar: AppBar(title: const Text('Daily Logs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLogSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Log'),
      ),
      body: _logs.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No Daily Logs Yet',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to record eggs and mortality',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // padding for FAB
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              final flockName = _flockNames[log.flockId] ?? 'Unknown Flock';
              final totalEggs = log.goodEggs + log.brokenEggs;
              
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
                          Text(
                            flockName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(log.date),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(
                            icon: Icons.egg_rounded, 
                            label: '${log.goodEggs} Good',
                            color: Colors.green,
                          ),
                          if (log.brokenEggs > 0)
                            _StatChip(
                              icon: Icons.egg_alt_rounded, 
                              label: '${log.brokenEggs} Broken',
                              color: Colors.orange,
                            ),
                          if (log.deadBirds > 0)
                            _StatChip(
                              icon: Icons.warning_rounded, 
                              label: '${log.deadBirds} Dead',
                              color: Colors.red,
                            ),
                          if (log.brokenEggs == 0 && log.deadBirds == 0)
                            _StatChip(
                              icon: Icons.check_circle_rounded, 
                              label: 'All Good',
                              color: Colors.blue,
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600, 
              color: color
            ),
          ),
        ],
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

