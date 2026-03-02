import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/models/flock.dart';
import '../../../shared/widgets/shared_widgets.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

class FlockFormSheet extends StatefulWidget {
  const FlockFormSheet({super.key, this.existing, required this.onSaved});
  final Flock? existing;
  final VoidCallback onSaved;

  @override
  State<FlockFormSheet> createState() => _FlockFormSheetState();
}

class _FlockFormSheetState extends State<FlockFormSheet> {
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
            Text(isEdit ? AppLocalizations.of(context)!.titleEditFlock : AppLocalizations.of(context)!.titleAddFlock,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.fieldFarmName.replaceAll('Farm', 'Flock'),
                  prefixIcon: const Icon(Icons.label_rounded)),
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _breedCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.fieldBreed,
                  prefixIcon: const Icon(Icons.category_rounded)),
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
            ),
            const SizedBox(height: 12),
            NumpadField(
              label: AppLocalizations.of(context)!.fieldInitialCount,
              controller: _countCtrl,
              prefixIcon: Icons.numbers_rounded,
            ),
            const SizedBox(height: 12),
            DatePickerTile(
              label: AppLocalizations.of(context)!.fieldStartDate,
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
                  ? AppLocalizations.of(context)!.msgSyncing
                  : isEdit
                      ? AppLocalizations.of(context)!.btnEdit
                      : AppLocalizations.of(context)!.btnAdd),
            ),
          ],
        ),
      ),
    );
  }
}
