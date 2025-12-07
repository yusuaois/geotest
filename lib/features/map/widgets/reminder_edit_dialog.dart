import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:triggeo/data/models/reminder_location.dart';
import 'package:triggeo/data/repositories/reminder_repository.dart';

class ReminderEditDialog extends ConsumerStatefulWidget {
  final LatLng position;
  final ReminderLocation? existingReminder; // 如果是编辑模式，传入此对象

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
        id: widget.existingReminder?.id, // 保持 ID 不变如果是编辑
        name: _nameController.text,
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        radius: _radius,
        isActive: true,
      );

      await repo.save(reminder); // Repository 会处理 save (put)

      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(widget.existingReminder == null ? "提醒已创建" : "提醒已更新")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingReminder == null ? "新建位置提醒" : "编辑位置提醒"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 经纬度显示
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "纬度: ${widget.position.latitude.toStringAsFixed(5)}\n经度: ${widget.position.longitude.toStringAsFixed(5)}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 名称输入
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "位置名称",
                  hintText: "例如：公司、超市",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? "请输入名称" : null,
              ),
              const SizedBox(height: 16),

              // 3. 半径滑块
              Text("提醒半径: ${_radius.toInt()} 米"),
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
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text("保存"),
        ),
      ],
    );
  }
}
