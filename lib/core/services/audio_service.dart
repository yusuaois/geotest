import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// 播放指定路径的音频文件
  Future<void> playCustomFile(String filePath) async {
    await stopPlay(); // 播放前先停止
    try {
      if (filePath.isNotEmpty && File(filePath).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        debugPrint("音频文件不存在: $filePath");
      }
    } catch (e) {
      debugPrint("播放音频失败: $e");
    }
  }

  /// 触发震动
  /// [pattern] 为 null 时执行默认长震动
  Future<void> vibrate({List<int>? pattern}) async {
    if (await Vibration.hasVibrator()) {
      if (pattern != null) {
        Vibration.vibrate(pattern: pattern);
      } else {
        // 默认震动模式：等待0ms，震动1000ms，等待500ms，震动1000ms
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000],amplitude: 255);
      }
    } else {
      debugPrint("设备不支持震动");
    }
  }

  /// 停止播放和震动
  Future<void> stop() async {
    await _audioPlayer.stop();
    Vibration.cancel();
  }

  // 停止播放
  Future<void> stopPlay() async {
    await _audioPlayer.stop();
  }

  // 停止震动
  Future<void> stopVibrate() async {
    Vibration.cancel();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
