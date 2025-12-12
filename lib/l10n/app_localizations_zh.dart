// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get helloWorld => '你好世界';

  @override
  String mapSearchFailed(Object error) {
    return '搜索失败: $error';
  }

  @override
  String mapGetLocationFailed(Object error) {
    return '获取位置失败: $error';
  }

  @override
  String get mapLocating => '正在定位...';

  @override
  String get mapSearchHint => '搜索地点';

  @override
  String get mapSearchEmptyError => '请输入搜索关键词';

  @override
  String mapLocationFailed(Object error) {
    return '定位失败: $error';
  }

  @override
  String get mapLongPressHint => '长按地图任意位置添加提醒';

  @override
  String get mapNoSearchResults => '没有找到搜索结果';

  @override
  String settingsRingtoneSaved(Object ringtoneName) {
    return '铃声已保存: $ringtoneName';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsThemeSection => '主题';

  @override
  String get settingsDynamic => '动态取色 (Material You)';

  @override
  String get settingsSystemWallpaperColor => '跟随系统壁纸颜色 (仅Android 12+)';

  @override
  String get settingsCustomThemeColor => '自定义主题色';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsLightMode => '浅色模式';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsReminderSection => '提醒设置';

  @override
  String get settingsReminderType => '提醒类型';

  @override
  String get settingsReminderRingtone => '响铃';

  @override
  String get settingsReminderVibration => '震动';

  @override
  String get settingsReminderBoth => '响铃与震动';

  @override
  String get settingsReminderVibrationNotSupport => '当前设备不支持震动';

  @override
  String get settingsCustomRingtone => '自定义提醒铃声';

  @override
  String get settingsPickRingtone => '点击选择音频文件';

  @override
  String settingsRintoneFileNotFound(Object filePath) {
    return '路径为 $filePath 的音频文件不存在';
  }

  @override
  String settingsRintonePlayFiled(Object error) {
    return '播放音频文件失败，错误信息: $error';
  }

  @override
  String get settingsTestSetting => '测试当前设置';

  @override
  String get settingsMapDataSection => '地图与数据';

  @override
  String get settingsOfflineMap => '离线地图';

  @override
  String get settingsManageOfflineMap => '管理已下载的地图';

  @override
  String get settingsTileSource => '地图源';

  @override
  String get settingsTileSourceRestart => '地图源已切换，重启应用生效';

  @override
  String get offlineMapAddedToQueue => '已加入下载队列';

  @override
  String get offlineMapTitle => '离线地图管理';

  @override
  String get offlineMapTabNew => '下载新地图';

  @override
  String get offlineMapTabTasks => '任务与已下载';

  @override
  String get offlineMapLoadingData => '正在加载离线地图数据...';

  @override
  String offlineMapLoadFailed(Object error) {
    return '加载失败: $error';
  }

  @override
  String get offlineMapSearchHint => '搜索城市';

  @override
  String get offlineMapSearchButton => '开始搜索';

  @override
  String get offlineMapSearching => '搜索中...';

  @override
  String get offlineMapNoResults => '没有找到搜索结果';

  @override
  String get offlineMapDownloadAction => '下载';

  @override
  String offlineMapStatusDownloading(Object percent) {
    return '下载中 $percent%';
  }

  @override
  String get offlineMapStatusCompleted => '已完成';

  @override
  String get offlineMapStatusFailed => '下载失败';

  @override
  String get offlineMapStatusPaused => '已暂停';

  @override
  String get offlineMapStatusCanceled => '已取消';

  @override
  String get offlineMapStatusPending => '等待中...';

  @override
  String get offlineMapPauseAction => '暂停';

  @override
  String get offlineMapResumeAction => '继续';

  @override
  String get offlineMapDeleteAction => '删除';

  @override
  String get offlineMapNoTasks => '暂无任务';

  @override
  String get reminderNameRequired => '请输入名称';

  @override
  String reminderSaveFailed(Object error) {
    return '保存失败: $error';
  }

  @override
  String get reminderDetailTitle => '设置提醒';

  @override
  String get reminderNameLabel => '位置名称';

  @override
  String get reminderNameHint => '例如：超市，公司';

  @override
  String reminderRadiusText(int radius) {
    return '提醒半径: $radius 米';
  }

  @override
  String get saveAction => '保存';

  @override
  String get reminderListTitle => '我的提醒';

  @override
  String get reminderListEmpty => '暂无提醒';

  @override
  String reminderListItemSubtitle(int radius, Object lat, Object lon) {
    return '半径: ${radius}m\n坐标: $lat, $lon';
  }

  @override
  String get reminderEditTitle => '添加/编辑提醒';

  @override
  String reminderDetailInfo(Object lat, Object lon) {
    return '纬度: $lat\n经度: $lon';
  }

  @override
  String get reminderCreated => '提醒已创建';

  @override
  String get reminderUpdated => '提醒已更新';

  @override
  String get cancelAction => '取消';

  @override
  String get backgroundServiceTitle => 'Triggeo 后台检测';

  @override
  String get backgroundServiceContent => '后台定位检测中...';

  @override
  String get backgroundServicePermissionError => '无法启动后台服务，请确保已授予位置权限';

  @override
  String get backgroundServiceAlwaysPermissionError =>
      '位置权限不足，请在系统设置中授予“始终”权限以确保后台提醒功能正常。';

  @override
  String get backgroundServiceStarted => '后台定位服务已启动';

  @override
  String get backgroundServiceStopped => '后台定位服务已停止';

  @override
  String locationServiceAlertTitle(Object name) {
    return '提醒触发: $name';
  }

  @override
  String locationServiceAlertBodyTitle(Object name) {
    return '📍 到达提醒: $name';
  }

  @override
  String get locationServiceAlertBodySubtitle => '您已到达目标区域';

  @override
  String get notificationChannelBackgroundName => '后台运行服务';

  @override
  String get notificationChannelBackgroundDesc => '保持应用在后台检测位置';

  @override
  String get notificationChannelAlertName => '位置到达提醒';

  @override
  String get notificationChannelAlertDesc => '当到达目的地时发出提醒';

  @override
  String get notificationChannelDownloadName => '地图下载进度';

  @override
  String get notificationChannelDownloadDesc => '显示离线地图下载的进度';

  @override
  String notificationDownloadProgressTitle(int activeTasks) {
    return '正在下载离线地图 ($activeTasks 个任务)';
  }

  @override
  String notificationDownloadFailedTitle(Object error) {
    return '下载失败: $error';
  }

  @override
  String get notificationDownloadFailedBody => '请检查网络并重试';
}
