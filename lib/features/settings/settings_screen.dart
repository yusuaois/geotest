import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/features/settings/offline_map_screen.dart';
import 'package:triggeo/features/settings/theme_controller.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';

// 定义提醒方式枚举 (建议放在单独的 model 文件中，这里为了方便直接展示)
enum GlobalReminderType { ringtone, vibration, both }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // 设置存储 Box
  late Box _settingsBox;

  // 状态变量
  GlobalReminderType _reminderType = GlobalReminderType.both;
  String? _customRingtonePath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = Hive.box('settings_box');
    setState(() {
      // 读取提醒方式，默认为 both (index 2)
      int typeIndex = _settingsBox.get('reminder_type', defaultValue: 2);
      _reminderType = GlobalReminderType.values[typeIndex];
      // 读取自定义铃声路径
      _customRingtonePath = _settingsBox.get('custom_ringtone_path');
    });
  }

  Future<void> _saveReminderType(GlobalReminderType type) async {
    setState(() => _reminderType = type);
    await _settingsBox.put('reminder_type', type.index);
  }

  Future<void> _pickAndSaveRingtone() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();

      // 重命名并保存到应用目录 (使用时间戳防止重名)
      final fileName =
          'ringtone_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourceFile.path)}';
      final savedFile = await sourceFile.copy('${appDir.path}/$fileName');

      setState(() {
        _customRingtonePath = savedFile.path;
      });

      // 持久化存储路径
      await _settingsBox.put('custom_ringtone_path', savedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("铃声已保存: ${result.files.single.name}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("应用设置")),
      body: ListView(
        children: [
          _buildSectionHeader(context, "提醒配置"),

          // --- 1. 提醒方式选择 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                RadioListTile<GlobalReminderType>(
                  title: const Text("仅铃声"),
                  value: GlobalReminderType.ringtone,
                  groupValue: _reminderType,
                  onChanged: (val) => _saveReminderType(val!),
                ),
                RadioListTile<GlobalReminderType>(
                  title: const Text("仅震动"),
                  value: GlobalReminderType.vibration,
                  groupValue: _reminderType,
                  onChanged: (val) => _saveReminderType(val!),
                ),
                RadioListTile<GlobalReminderType>(
                  title: const Text("铃声 + 震动"),
                  value: GlobalReminderType.both,
                  groupValue: _reminderType,
                  onChanged: (val) => _saveReminderType(val!),
                ),
              ],
            ),
          ),

          const Divider(),

          // --- 2. 自定义铃声管理 ---
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text("选择自定义铃声"),
            subtitle: Text(_customRingtonePath != null
                ? "当前: ${path.basename(_customRingtonePath!)}"
                : "点击选择本地音频文件"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickAndSaveRingtone,
          ),

          ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text("测试当前配置"),
            onTap: () async {
              // 根据当前设置测试播放/震动
              if ((_reminderType == GlobalReminderType.ringtone ||
                      _reminderType == GlobalReminderType.both) &&
                  _customRingtonePath != null) {
                audioService.playCustomFile(_customRingtonePath!);
              }
              if (_reminderType == GlobalReminderType.vibration ||
                  _reminderType == GlobalReminderType.both) {
                audioService.vibrate();
              }
            },
          ),

          const Divider(),
          _buildSectionHeader(context, "外观"),
          // ... (保留原有的外观设置代码) ...
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
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple
                ]
                    .map((color) => GestureDetector(
                          onTap: () => themeNotifier.setCustomSeedColor(color),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: themeState.customSeedColor == color
                                    ? Colors.black
                                    : Colors.transparent,
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
                DropdownMenuItem(
                    value: AppThemeMode.system, child: Text("跟随系统")),
                DropdownMenuItem(value: AppThemeMode.light, child: Text("浅色")),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text("深色")),
              ],
            ),
          ),

          // ... 其他外观组件 ...
          const Divider(),
          _buildSectionHeader(context, "地图数据"), // New Section Header
          ListTile(
            leading: const Icon(Icons.download_for_offline),
            title: const Text("离线地图管理"),
            subtitle: const Text("下载离线地图数据"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OfflineMapScreen()),
              );
            },
          ),

          const Divider(),
          Consumer(
            builder: (context, ref, child) {
              final settingsRepo = ref.watch(settingsRepositoryProvider);
              final currentIndex = settingsRepo.getCurrentTileSourceIndex();
              final theme = Theme.of(context);

              return ListTile(
                title: const Text("地图源"),
                subtitle: Text(kTileSources[currentIndex].name),
                trailing: PopupMenuButton<int>(
                  // 1. 显式设置菜单背景色，确保与卡片或背景区分
                  color: theme.colorScheme.surfaceContainerHigh, 
                  initialValue: currentIndex,
                  // 2. 调整图标颜色
                  icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
                  onSelected: (index) async {
                    await settingsRepo.setTileSource(index);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("地图源已切换，请重新进入地图页生效")),
                      );
                    }
                  },
                  itemBuilder: (context) =>
                      List.generate(kTileSources.length, (index) {
                    final isSelected = index == currentIndex;
                    return PopupMenuItem(
                      value: index,
                      child: Row(
                        children: [
                          // 添加选中指示器
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              kTileSources[index].name,
                              style: TextStyle(
                                // 3. 显式设置文字颜色，确保对比度
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
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
