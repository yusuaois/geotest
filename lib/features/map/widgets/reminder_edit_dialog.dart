import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/l10n/app_localizations.dart';

class ReminderEditDialog extends ConsumerStatefulWidget {
  final LatLng position;
  final ReminderLocation? existingReminder;

  const ReminderEditDialog({
    super.key,
    required this.position,
    this.existingReminder,
  });

  @override
  ConsumerState<ReminderEditDialog> createState() => _ReminderEditDialogState();
}

class _ReminderEditDialogState extends ConsumerState<ReminderEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingReminder?.name ?? '');
    _radius = widget.existingReminder?.radius ?? 500.0;
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(reminderRepositoryProvider);

      final reminder = ReminderLocation(
        id: widget.existingReminder?.id,
        name: _nameController.text,
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        radius: _radius,
        isActive: true,
      );

      await repo.save(reminder);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existingReminder == null
                  ? AppLocalizations.of(context)!.reminderCreated
                  : AppLocalizations.of(context)!.reminderUpdated)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.reminderEditTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show coordinates
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.reminderDetailInfo(
                    widget.position.latitude.toStringAsFixed(5),
                    widget.position.longitude.toStringAsFixed(5),
                  ),
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // Input for name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.reminderNameLabel,
                  hintText: AppLocalizations.of(context)!.reminderNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? AppLocalizations.of(context)!.reminderNameRequired
                    : null,
              ),
              const SizedBox(height: 16),

              // Radius slider
              Text(AppLocalizations.of(context)!
                  .reminderRadiusText(_radius.toInt())),
              Slider(
                value: _radius,
                min: 100,
                max: 2000,
                divisions: 19,
                label: "${_radius.toInt()}m",
                onChanged: (val) => setState(() => _radius = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancelAction),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(AppLocalizations.of(context)!.saveAction),
        ),
      ],
    );
  }
}
