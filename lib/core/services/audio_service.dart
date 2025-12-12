import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:triggeo/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play audio from a custom file path
  Future<void> playCustomFile(String filePath, BuildContext context) async {
    await stopPlay();
    try {
      if (filePath.isNotEmpty && File(filePath).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(filePath));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .settingsRintoneFileNotFound(filePath))));
        debugPrint("Unable to play audio, file not found: $filePath");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .settingsRintonePlayFiled(filePath))));
      debugPrint("Failed to play audio: $e");
    }
  }

  /// Vibrate the device
  Future<void> vibrate(BuildContext context, {List<int>? pattern}) async {
    if (await Vibration.hasVibrator()) {
      if (pattern != null) {
        Vibration.vibrate(pattern: pattern);
      } else {
        Vibration.vibrate(
            pattern: [0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000],
            amplitude: 255);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .settingsReminderVibrationNotSupport)),
      );
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
