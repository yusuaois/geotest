import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 播放默认铃声 (Assets)
  Future<void> playDefaultAlert() async {
    await stop(); // 先停止当前播放
    // 假设你稍后会在 assets/audio/ 放入 alert.mp3
    // 如果没有文件，这行代码会报错，请确保 assets 存在
    // await _audioPlayer.play(AssetSource('audio/default_alert.mp3'));
    
    // 暂时用一个简单的 web URL 测试，或者你可以暂时注释掉
    // 实际项目中请使用 AssetSource
  }

  // 播放自定义文件
  Future<void> playCustomFile(String filePath) async {
    await stop();
    await _audioPlayer.play(DeviceFileSource(filePath));
  }

  // 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}