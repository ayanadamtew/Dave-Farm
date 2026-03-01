import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/flock.dart';
import '../../shared/widgets/shared_widgets.dart';

class FlocksScreen extends StatefulWidget {
  const FlocksScreen({super.key});

  @override
  State<FlocksScreen> createState() => _FlocksScreenState();
}

class _FlocksScreenState extends State<FlocksScreen> {
  List<Flock> _flocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFlocks();
  }

  Future<void> _loadFlocks() async {
    setState(() => _loading = true);
    final flocks = await DatabaseHelper.instance.getAllFlocks();
    if (mounted) setState(() { _flocks = flocks; _loading = false; });
  }

  void _openAddFlock([Flock? existing]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FlockFormSheet(
        existing: existing,
        onSaved: _loadFlocks,
      ),
    );
  }

  Future<void> _deleteFlock(Flock f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Flock?'),
        content: Text('Remove "${f.name}" and all its data?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteFlock(f.id);
      _loadFlocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flocks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFlock(),
        icon: const Icon(Icons.add),
        label: const Text('Add Flock'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flocks.isEmpty
              ? _EmptyState(onAdd: () => _openAddFlock())
              : RefreshIndicator(
                  onRefresh: _loadFlocks,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _flocks.length,
                    itemBuilder: (_, i) {
                      final f = _flocks[i];
                      return _FlockCard(
                        flock: f,
                        onEdit: () => _openAddFlock(f),
                        onDelete: () => _deleteFlock(f),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FlockCard extends StatelessWidget {
  const _FlockCard({
    required this.flock,
    required this.onEdit,
    required this.onDelete,
  });

  final Flock flock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final startFmt = DateFormat('MMM d, yyyy').format(flock.startDate);
    final survivalRate = flock.initialBirdCount > 0
        ? ((flock.currentBirdCount / flock.initialBirdCount) * 100)
            .toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.egg_rounded,
                      color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flock.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('${flock.breed} · Started $startFmt',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Current', '${flock.currentBirdCount}',
                    Icons.pets_rounded, Colors.greenAccent),
                _Stat('Initial', '${flock.initialBirdCount}',
                    Icons.numbers_rounded, Colors.white54),
                _Stat('Survival', '$survivalRate%',
                    Icons.show_chart_rounded, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.egg_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No flocks yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Add your first batch of birds to get started.',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add First Flock'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add / Edit Flock Bottom Sheet
// ─────────────────────────────────────────────

class _FlockFormSheet extends StatefulWidget {
  const _FlockFormSheet({this.existing, required this.onSaved});
  final Flock? existing;
  final VoidCallback onSaved;

  @override
  State<_FlockFormSheet> createState() => _FlockFormSheetState();
}

class _FlockFormSheetState extends State<_FlockFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _countCtrl;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _breedCtrl =
        TextEditingController(text: widget.existing?.breed ?? '');
    _countCtrl = TextEditingController(
        text: widget.existing?.initialBirdCount.toString() ?? '');
    if (widget.existing != null) {
      _startDate = widget.existing!.startDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = DatabaseHelper.instance;
    if (widget.existing == null) {
      final f = Flock.create(
        name: _nameCtrl.text.trim(),
        startDate: _startDate,
        initialBirdCount: int.parse(_countCtrl.text),
        breed: _breedCtrl.text.trim(),
      );
      await db.insertFlock(f);
    } else {
      final updated = widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        breed: _breedCtrl.text.trim(),
        startDate: _startDate,
        initialBirdCount: int.tryParse(_countCtrl.text),
        isSynced: 0, // mark dirty for re-sync
      );
      await db.updateFlock(updated);
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Flock' : 'Add Flock',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Flock Name',
                  prefixIcon: Icon(Icons.label_rounded)),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Breed',
                  prefixIcon: Icon(Icons.category_rounded)),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            NumpadField(
              label: 'Initial Bird Count',
              controller: _countCtrl,
              prefixIcon: Icons.numbers_rounded,
            ),
            const SizedBox(height: 12),
            DatePickerTile(
              label: 'Start Date',
              date: _startDate,
              onChanged: (d) => setState(() => _startDate = d),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving
                  ? 'Saving…'
                  : isEdit
                      ? 'Update Flock'
                      : 'Add Flock'),
            ),
          ],
        ),
      ),
    );
  }
}
