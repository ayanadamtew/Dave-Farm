import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/daily_log.dart';
import '../../core/models/flock.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goodEggsCtrl = TextEditingController();
  final _brokenEggsCtrl = TextEditingController();
  final _damagedEggsCtrl = TextEditingController();
  final _deadBirdsCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<Flock> _flocks = [];
  Flock? _selectedFlock;
  bool _isSaving = false;
  
  List<DailyLog> _logs = [];

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
        // Sort logs descending by date
        _logs.sort((a, b) => b.date.compareTo(a.date));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlock == null) {
      _showSnack(AppLocalizations.of(context)!.labelChooseFlock);
      return;
    }
    setState(() => _isSaving = true);

    final log = DailyLog.create(
      flockId: _selectedFlock!.id,
      date: _selectedDate,
      goodEggs: int.tryParse(_goodEggsCtrl.text) ?? 0,
      brokenEggs: int.tryParse(_brokenEggsCtrl.text) ?? 0,
      damagedEggs: int.tryParse(_damagedEggsCtrl.text) ?? 0,
      deadBirds: int.tryParse(_deadBirdsCtrl.text) ?? 0,
    );

    await DatabaseHelper.instance.insertDailyLog(log);

    if (mounted) {
      setState(() => _isSaving = false);
      _showSnack(AppLocalizations.of(context)!.msgSaved);
      _resetForm();
      Navigator.pop(context); // Close the modal sheet
      _loadData(); // Refresh the list
    }
  }

  void _resetForm() {
    _goodEggsCtrl.clear();
    _brokenEggsCtrl.clear();
    _damagedEggsCtrl.clear();
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
    _damagedEggsCtrl.dispose();
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
                      AppLocalizations.of(context)!.titleDailyLog,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Flock selector
                    _SectionLabel(AppLocalizations.of(context)!.labelSelectFlock),
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
                          Expanded(child: Text('No flocks found. Add a flock first.')),
                        ]),
                      )
                    else
                      DropdownButtonFormField<Flock>(
                        value: _selectedFlock,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.group_rounded),
                        ),
                        hint: Text(AppLocalizations.of(context)!.labelChooseFlock),
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
                    _SectionLabel(AppLocalizations.of(context)!.fieldDate),
                    DatePickerTile(
                      label: AppLocalizations.of(context)!.fieldDate,
                      date: _selectedDate,
                      onChanged: (d) => setSheetState(() => _selectedDate = d),
                    ),
                    const Divider(height: 32),
      
                    // Egg counts
                    _SectionLabel(AppLocalizations.of(context)!.labelEggCount),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: NumpadField(
                          label: AppLocalizations.of(context)!.labelGood,
                          controller: _goodEggsCtrl,
                          prefixIcon: Icons.egg_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NumpadField(
                          label: AppLocalizations.of(context)!.labelBroken,
                          controller: _brokenEggsCtrl,
                          prefixIcon: Icons.egg_alt_rounded,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    NumpadField(
                      label: AppLocalizations.of(context)!.fieldDamagedEggs,
                      controller: _damagedEggsCtrl,
                      prefixIcon: Icons.heart_broken_rounded,
                    ),
                    const SizedBox(height: 20),
      
                    // Mortality
                    _SectionLabel(AppLocalizations.of(context)!.labelMortality),
                    const SizedBox(height: 12),
                    NumpadField(
                      label: AppLocalizations.of(context)!.fieldDeadBirds,
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
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.labelMortalityHint,
                            style: const TextStyle(fontSize: 11, color: Colors.amber),
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
                        label: Text(_isSaving ? AppLocalizations.of(context)!.msgSyncing : AppLocalizations.of(context)!.btnSave),
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navLogs)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddLogSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppLocalizations.of(context)!.labelAddLog),
      ),
      body: _logs.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.labelEmptyLogs,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.labelEmptyLogsSub,
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
              final totalEggs = log.goodEggs + log.brokenEggs + log.damagedEggs;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Theme.of(context).cardColor.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy (EEEE)').format(log.date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.egg_rounded, size: 12, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalEggs',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _LogStatItem(
                              label: AppLocalizations.of(context)!.labelGood,
                              value: '${log.goodEggs}',
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LogStatItem(
                              label: AppLocalizations.of(context)!.labelBroken,
                              value: '${log.brokenEggs}',
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LogStatItem(
                              label: AppLocalizations.of(context)!.labelDamaged,
                              value: '${log.damagedEggs}',
                              color: Colors.deepOrangeAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LogStatItem(
                              label: AppLocalizations.of(context)!.labelDead,
                              value: '${log.deadBirds}',
                              color: log.deadBirds > 0 ? Colors.redAccent : Colors.white24,
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

class _LogStatItem extends StatelessWidget {
  const _LogStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
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

