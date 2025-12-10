import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play audio from a custom file path
  Future<void> playCustomFile(String filePath) async {
    await stopPlay();
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

  /// Vibrate the device
  Future<void> vibrate({List<int>? pattern}) async {
    if (await Vibration.hasVibrator()) {
      if (pattern != null) {
        Vibration.vibrate(pattern: pattern);
      } else {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000],amplitude: 255);
      }
    } else {
      debugPrint("设备不支持震动");
    }
  }

  /// Stop the audio player and vibration
  Future<void> stop() async {
    await _audioPlayer.stop();
    Vibration.cancel();
  }

  // Stop playing audio
  Future<void> stopPlay() async {
    await _audioPlayer.stop();
  }

  // Stop vibration
  Future<void> stopVibrate() async {
    Vibration.cancel();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
