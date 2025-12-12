// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World';

  @override
  String mapSearchFailed(Object error) {
    return 'Search failed: $error';
  }

  @override
  String mapGetLocationFailed(Object error) {
    return ' Get location failed: $error';
  }

  @override
  String get mapLocating => 'Locating...';

  @override
  String get mapSearchHint => 'Search location';

  @override
  String get mapSearchEmptyError => 'Please enter search keywords';

  @override
  String mapLocationFailed(Object error) {
    return 'Location failed: $error';
  }

  @override
  String get mapLongPressHint =>
      'Long press anywhere on the map to add a reminder';

  @override
  String get mapNoSearchResults => 'No search results found';

  @override
  String settingsRingtoneSaved(Object ringtoneName) {
    return 'Ringtone saved: $ringtoneName';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThemeSection => 'Theme';

  @override
  String get settingsDynamic => 'Dynamic Color (Material You)';

  @override
  String get settingsSystemWallpaperColor => 'System Wallpaper Color';

  @override
  String get settingsCustomThemeColor => 'Custom Theme Color';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsLightMode => 'Light Mode';

  @override
  String get settingsThemeSystem => 'Follow System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsReminderSection => 'Reminder Settings';

  @override
  String get settingsReminderType => 'Reminder Type';

  @override
  String get settingsReminderRingtone => 'Ring';

  @override
  String get settingsReminderVibration => 'Vibrate';

  @override
  String get settingsReminderBoth => 'Ring & Vibrate';

  @override
  String get settingsReminderVibrationNotSupport =>
      'Vibration is not supported on this device';

  @override
  String get settingsCustomRingtone => 'Custom Reminder Ringtone';

  @override
  String get settingsPickRingtone => 'Tap to select audio file';

  @override
  String settingsRintoneFileNotFound(Object filePath) {
    return 'Unable to play audio, file not found: $filePath';
  }

  @override
  String settingsRintonePlayFiled(Object error) {
    return 'Unable to play audio: $error';
  }

  @override
  String get settingsTestSetting => 'Test Setting';

  @override
  String get settingsMapDataSection => 'Map & Data';

  @override
  String get settingsOfflineMap => 'Offline Maps';

  @override
  String get settingsManageOfflineMap => 'Manage Downloaded Maps';

  @override
  String get settingsTileSource => 'Tile Source';

  @override
  String get settingsTileSourceRestart =>
      'Tile source changed. Restart app to take effect';

  @override
  String get offlineMapAddedToQueue => 'Added to download queue';

  @override
  String get offlineMapTitle => 'Offline Map Management';

  @override
  String get offlineMapTabNew => 'Download New Map';

  @override
  String get offlineMapTabTasks => 'Tasks & Downloaded';

  @override
  String get offlineMapLoadingData => 'Loading offline map data...';

  @override
  String offlineMapLoadFailed(Object error) {
    return 'Load failed: $error';
  }

  @override
  String get offlineMapSearchHint => 'Search city';

  @override
  String get offlineMapSearchButton => 'Search';

  @override
  String get offlineMapSearching => 'Searching...';

  @override
  String get offlineMapNoResults => 'No results found';

  @override
  String get offlineMapDownloadAction => 'Download';

  @override
  String offlineMapStatusDownloading(Object percent) {
    return 'Downloading $percent%';
  }

  @override
  String get offlineMapStatusCompleted => 'Completed';

  @override
  String get offlineMapStatusFailed => 'Download failed';

  @override
  String get offlineMapStatusPaused => 'Paused';

  @override
  String get offlineMapStatusCanceled => 'Canceled';

  @override
  String get offlineMapStatusPending => 'Pending...';

  @override
  String get offlineMapPauseAction => 'Pause';

  @override
  String get offlineMapResumeAction => 'Resume';

  @override
  String get offlineMapDeleteAction => 'Delete';

  @override
  String get offlineMapNoTasks => 'No tasks';

  @override
  String get reminderNameRequired => 'Please enter a name';

  @override
  String reminderSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get reminderDetailTitle => 'Set Reminder';

  @override
  String get reminderNameLabel => 'Location Name';

  @override
  String get reminderNameHint => 'e.g., Supermarket, Office';

  @override
  String reminderRadiusText(int radius) {
    return 'Reminder radius: $radius meters';
  }

  @override
  String get saveAction => 'Save';

  @override
  String get reminderListTitle => 'My Reminders';

  @override
  String get reminderListEmpty => 'No reminders yet';

  @override
  String reminderListItemSubtitle(int radius, Object lat, Object lon) {
    return 'Radius: ${radius}m\nCoordinates: $lat, $lon';
  }

  @override
  String get reminderEditTitle => 'Add/Edit Reminder';

  @override
  String reminderDetailInfo(Object lat, Object lon) {
    return 'Latitude: $lat\nLontitude: $lon';
  }

  @override
  String get reminderCreated => 'Reminder created';

  @override
  String get reminderUpdated => 'Reminder updated';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get backgroundServiceTitle => 'Triggeo Background Detection';

  @override
  String get backgroundServiceContent =>
      'Background location detection running...';

  @override
  String get backgroundServicePermissionError =>
      'Unable to start background service. Please ensure location permission is granted.';

  @override
  String get backgroundServiceAlwaysPermissionError =>
      'Insufficient location permission. Please grant \"Always\" permission in system settings to ensure background reminder functionality.';

  @override
  String get backgroundServiceStarted => 'Background location service started';

  @override
  String get backgroundServiceStopped => 'Background location service stopped';

  @override
  String locationServiceAlertTitle(Object name) {
    return 'Reminder Triggered: $name';
  }

  @override
  String locationServiceAlertBodyTitle(Object name) {
    return '📍 Arrival Alert: $name';
  }

  @override
  String get locationServiceAlertBodySubtitle =>
      'You have arrived at Target Location';

  @override
  String get notificationChannelBackgroundName => 'Background Running Service';

  @override
  String get notificationChannelBackgroundDesc =>
      'Keep app running in background to detect location';

  @override
  String get notificationChannelAlertName => 'Location Arrival Reminder';

  @override
  String get notificationChannelAlertDesc =>
      'Notify when arriving at a destination';

  @override
  String get notificationChannelDownloadName => 'Map Download Progress';

  @override
  String get notificationChannelDownloadDesc =>
      'Show progress of offline map downloads';

  @override
  String notificationDownloadProgressTitle(int activeTasks) {
    return 'Downloading offline map ($activeTasks tasks)';
  }

  @override
  String notificationDownloadFailedTitle(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get notificationDownloadFailedBody =>
      'Please check network and try again';
}
