import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:triggeo/core/services/service_locator.dart';
import 'package:triggeo/features/settings/offline_map_screen.dart';
import 'package:triggeo/features/settings/theme_controller.dart';
import 'package:triggeo/data/repositories/settings_repository.dart';

enum GlobalReminderType { ringtone, vibration, both }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Box _settingsBox;

  GlobalReminderType _reminderType = GlobalReminderType.both;
  String? _customRingtonePath;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _loadSettings() async {
    _settingsBox = Hive.box('settings_box');
    setState(() {
      int typeIndex = _settingsBox.get('reminder_type', defaultValue: 2);
      _reminderType = GlobalReminderType.values[typeIndex];
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

      final fileName =
          'ringtone_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourceFile.path)}';
      final savedFile = await sourceFile.copy('${appDir.path}/$fileName');

      setState(() {
        _customRingtonePath = savedFile.path;
      });

      await _settingsBox.put('custom_ringtone_path', savedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("铃声已保存: ${result.files.single.name}")),
        );
      }
    }
  }

  void _navigateToAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutScreen(
          packageInfo: _packageInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final audioService = ref.read(audioServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("应用设置"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _navigateToAboutPage,
            tooltip: "关于",
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, "提醒配置"),

          // Notification
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

          // Custom Ringtone
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
              Theme.of(context);

              return ListTile(
                title: const Text("地图源"),
                subtitle: Text(kTileSources[currentIndex].name),
                trailing: PopupMenuButton<int>(
                  initialValue: currentIndex,
                  onSelected: (index) async {
                    await settingsRepo.setTileSource(index);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("地图源已切换，重启应用生效")),
                    );
                  },
                  itemBuilder: (context) =>
                      List.generate(kTileSources.length, (index) {
                    return PopupMenuItem(
                      value: index,
                      child: Text(kTileSources[index].name),
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

// 关于页面
class AboutScreen extends StatefulWidget {
  final PackageInfo packageInfo;

  const AboutScreen({super.key, required this.packageInfo});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checkingUpdate = false;
  String? _updateInfo;

  // 模拟检查更新 - 实际项目中需要连接到你的GitHub仓库API
  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingUpdate = true;
      _updateInfo = null;
    });

    await Future.delayed(const Duration(seconds: 1)); // 模拟网络延迟

    // 这里应该是从GitHub API获取最新版本信息
    // 示例：https://api.github.com/repos/用户名/仓库名/releases/latest
    // 实际使用时需要替换为你的仓库地址

    setState(() {
      _checkingUpdate = false;
      _updateInfo = "当前已是最新版本 v${widget.packageInfo.version}";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("已检查更新")),
    );
  }

  Future<void> _launchGitHub() async {
    const url = 'https://github.com/yourusername/yourrepository';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("无法打开链接")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("关于"),
      ),
      body: ListView(
        children: [
          // 应用图标和名称
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                // 这里可以替换为你的应用图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.map,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.packageInfo.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  "版本 ${widget.packageInfo.version} (${widget.packageInfo.buildNumber})",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const Divider(),

          // 版本信息
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("应用名称"),
            subtitle: Text(widget.packageInfo.appName),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text("版本号"),
            subtitle: Text("${widget.packageInfo.version} (${widget.packageInfo.buildNumber})"),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("作者"),
            subtitle: const Text("Your Name"), // 替换为你的名字
          ),

          // GitHub仓库
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text("GitHub仓库"),
            subtitle: const Text("github.com/yourusername/yourrepository"), // 替换为你的仓库地址
            trailing: const Icon(Icons.open_in_new),
            onTap: _launchGitHub,
          ),

          const Divider(),

          // 检查更新
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_checkingUpdate)
                  const LinearProgressIndicator(),
                
                if (_updateInfo != null && !_checkingUpdate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _updateInfo!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                
                FilledButton(
                  onPressed: _checkingUpdate ? null : _checkForUpdates,
                  child: _checkingUpdate
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("检查更新中..."),
                          ],
                        )
                      : const Text("检查更新"),
                ),
              ],
            ),
          ),

          // 许可证信息
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "© 2025 AnchialC. All rights reserved.\nThis app is open source under MIT License.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}