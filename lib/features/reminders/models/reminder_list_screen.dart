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
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("半径: ${item.radius.toInt()} 米"),
                      Text(
                        "坐标: ${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
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
