import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triggeo/features/settings/theme_controller.dart'; // 引用之前的 ThemeController
import 'package:file_picker/file_picker.dart';
import 'package:vibration/vibration.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("应用设置")),
      body: ListView(
        children: [
          _buildSectionHeader(context, "外观"),
          SwitchListTile(
            title: const Text("动态取色 (Material You)"),
            subtitle: const Text("跟随系统壁纸颜色 (仅Android 12+)"),
            value: themeState.useDynamicColor,
            onChanged: (val) => themeNotifier.toggleDynamicColor(val),
          ),
          if (!themeState.useDynamicColor)
            ListTile(
              title: const Text("自定义主题色"),
              subtitle: Wrap(
                spacing: 8,
                children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple]
                    .map((color) => GestureDetector(
                          onTap: () => themeNotifier.setCustomSeedColor(color),
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeState.customSeedColor == color ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ListTile(
            title: const Text("深色模式"),
            trailing: DropdownButton<AppThemeMode>(
              value: themeState.mode,
              onChanged: (AppThemeMode? newValue) {
                if (newValue != null) themeNotifier.setThemeMode(newValue);
              },
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text("跟随系统")),
                DropdownMenuItem(value: AppThemeMode.light, child: Text("浅色")),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text("深色")),
              ],
            ),
          ),

          const Divider(),
          _buildSectionHeader(context, "提醒配置"),
          
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("自定义铃声"),
            subtitle: const Text("点击选择本地音频文件"),
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (result != null) {
                // TODO: 保存路径到 Hive 设置 Box
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已选择: ${result.files.single.name}")));
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text("测试铃声"),
            onTap: () async {
              if (await Vibration.hasVibrator() ?? false) {
                // TODO: 播放铃声
              }
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.vibration),
            title: const Text("测试震动"),
            onTap: () async {
              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 5000);
              }else{
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("设备不支持震动")));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}