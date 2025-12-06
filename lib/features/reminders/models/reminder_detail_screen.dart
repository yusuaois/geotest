import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';

class ReminderDetailScreen extends ConsumerStatefulWidget {
  final LatLng target;
  const ReminderDetailScreen({super.key, required this.target});

  @override
  ConsumerState<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends ConsumerState<ReminderDetailScreen> {
  final _nameController = TextEditingController();
  double _radius = 100;

  void _save() async {
    // 1. 基本校验
    if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入名称')));
        return;
    }

    try {
        debugPrint("开始保存提醒...");
        
        final reminder = ReminderLocation(
          name: _nameController.text,
          latitude: widget.target.latitude,
          longitude: widget.target.longitude,
          radius: _radius,
          isActive: true,
        );

        // 2. 调用 Repository 保存
        final repo = ref.read(reminderRepositoryProvider);
        await repo.save(reminder);
        
        debugPrint("保存成功，准备返回");

        if (mounted) {
            context.pop(); // 关闭页面
        }
    } catch (e) {
        // 3. 捕获异常
        debugPrint("保存失败: $e");
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('保存失败: $e'))
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("设置提醒")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "位置名称", hintText: "例如：超市，公司"),
            ),
            const SizedBox(height: 20),
            Text("提醒半径: ${_radius.toInt()} 米"),
            Slider(
              value: _radius,
              min: 50,
              max: 1000,
              divisions: 19,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text("保存提醒")),
            )
          ],
        ),
      ),
    );
  }
}