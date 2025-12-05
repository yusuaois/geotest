import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_controller.dart';

class SimpleSettingsCard extends ConsumerWidget {
  const SimpleSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("外观设置", style: Theme.of(context).textTheme.titleLarge),
            SwitchListTile(
              title: const Text("使用动态壁纸取色 (Material You)"),
              value: themeState.useDynamicColor,
              onChanged: (val) => controller.toggleDynamicColor(val),
            ),
            if (!themeState.useDynamicColor) ...[
              const SizedBox(height: 10),
              const Text("选择主题色:"),
              Wrap(
                spacing: 8,
                children: [Colors.blue, Colors.red, Colors.green, Colors.purple]
                    .map((color) => GestureDetector(
                          onTap: () => controller.setCustomSeedColor(color),
                          child: CircleAvatar(
                            backgroundColor: color,
                            radius: 16,
                            child: themeState.customSeedColor.value == color.value
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ],
            const Divider(),
            const Text("主题模式:"),
            SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.system, label: Text("系统")),
                ButtonSegment(value: AppThemeMode.light, label: Text("浅色")),
                ButtonSegment(value: AppThemeMode.dark, label: Text("深色")),
              ],
              selected: {themeState.mode},
              onSelectionChanged: (newSelection) {
                controller.setThemeMode(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}