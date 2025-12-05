import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("我的提醒")),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (reminders) {
          if (reminders.isEmpty) return const Center(child: Text("暂无提醒"));
          
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
                  subtitle: Text("半径: ${item.radius.toInt()}m"),
                  value: item.isActive,
                  onChanged: (val) {
                    item.isActive = val;
                    item.save(); // HiveObject 自带 save 方法
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}