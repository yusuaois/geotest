import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';
import 'package:triggeo/features/map/widgets/reminder_edit_dialog.dart';
import 'package:triggeo/l10n/app_localizations.dart';

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.reminderListTitle)),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reminders) {
          if (reminders.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.reminderListEmpty));

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final item = reminders[index];
              return Dismissible(
                key: Key(item.id),
                background: Container(color: Colors.red),
                onDismissed: (_) {
                  ref.read(reminderRepositoryProvider).delete(item.id);
                },
                child: SwitchListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    AppLocalizations.of(context)!.reminderListItemSubtitle(
                      item.radius.toInt(),
                      item.latitude.toStringAsFixed(4),
                      item.longitude.toStringAsFixed(4),
                    ),
                  ),
                  isThreeLine: true,
                  value: item.isActive,
                  onChanged: (val) {
                    item.isActive = val;
                    item.save();
                  },
                  secondary: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ReminderEditDialog(
                          position: LatLng(item.latitude, item.longitude),
                          existingReminder: item,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
