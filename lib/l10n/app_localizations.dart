import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get helloWorld;

  /// No description provided for @mapSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String mapSearchFailed(Object error);

  /// No description provided for @mapGetLocationFailed.
  ///
  /// In en, this message translates to:
  /// **' Get location failed: {error}'**
  String mapGetLocationFailed(Object error);

  /// No description provided for @mapLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get mapLocating;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get mapSearchHint;

  /// No description provided for @mapSearchEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter search keywords'**
  String get mapSearchEmptyError;

  /// No description provided for @mapLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Location failed: {error}'**
  String mapLocationFailed(Object error);

  /// No description provided for @mapLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long press anywhere on the map to add a reminder'**
  String get mapLongPressHint;

  /// No description provided for @mapNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get mapNoSearchResults;

  /// No description provided for @settingsRingtoneSaved.
  ///
  /// In en, this message translates to:
  /// **'Ringtone saved: {ringtoneName}'**
  String settingsRingtoneSaved(Object ringtoneName);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThemeSection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeSection;

  /// No description provided for @settingsDynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color (Material You)'**
  String get settingsDynamic;

  /// No description provided for @settingsSystemWallpaperColor.
  ///
  /// In en, this message translates to:
  /// **'System Wallpaper Color'**
  String get settingsSystemWallpaperColor;

  /// No description provided for @settingsCustomThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Theme Color'**
  String get settingsCustomThemeColor;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get settingsLightMode;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsReminderSection.
  ///
  /// In en, this message translates to:
  /// **'Reminder Settings'**
  String get settingsReminderSection;

  /// No description provided for @settingsReminderType.
  ///
  /// In en, this message translates to:
  /// **'Reminder Type'**
  String get settingsReminderType;

  /// No description provided for @settingsReminderRingtone.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get settingsReminderRingtone;

  /// No description provided for @settingsReminderVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get settingsReminderVibration;

  /// No description provided for @settingsReminderBoth.
  ///
  /// In en, this message translates to:
  /// **'Ring & Vibrate'**
  String get settingsReminderBoth;

  /// No description provided for @settingsReminderVibrationNotSupport.
  ///
  /// In en, this message translates to:
  /// **'Vibration is not supported on this device'**
  String get settingsReminderVibrationNotSupport;

  /// No description provided for @settingsCustomRingtone.
  ///
  /// In en, this message translates to:
  /// **'Custom Reminder Ringtone'**
  String get settingsCustomRingtone;

  /// No description provided for @settingsPickRingtone.
  ///
  /// In en, this message translates to:
  /// **'Tap to select audio file'**
  String get settingsPickRingtone;

  /// No description provided for @settingsRintoneFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Unable to play audio, file not found: {filePath}'**
  String settingsRintoneFileNotFound(Object filePath);

  /// No description provided for @settingsRintonePlayFiled.
  ///
  /// In en, this message translates to:
  /// **'Unable to play audio: {error}'**
  String settingsRintonePlayFiled(Object error);

  /// No description provided for @settingsTestSetting.
  ///
  /// In en, this message translates to:
  /// **'Test Setting'**
  String get settingsTestSetting;

  /// No description provided for @settingsMapDataSection.
  ///
  /// In en, this message translates to:
  /// **'Map & Data'**
  String get settingsMapDataSection;

  /// No description provided for @settingsOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get settingsOfflineMap;

  /// No description provided for @settingsManageOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Manage Downloaded Maps'**
  String get settingsManageOfflineMap;

  /// No description provided for @settingsTileSource.
  ///
  /// In en, this message translates to:
  /// **'Tile Source'**
  String get settingsTileSource;

  /// No description provided for @settingsTileSourceRestart.
  ///
  /// In en, this message translates to:
  /// **'Tile source changed. Restart app to take effect'**
  String get settingsTileSourceRestart;

  /// No description provided for @offlineMapAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to download queue'**
  String get offlineMapAddedToQueue;

  /// No description provided for @offlineMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Map Management'**
  String get offlineMapTitle;

  /// No description provided for @offlineMapTabNew.
  ///
  /// In en, this message translates to:
  /// **'Download New Map'**
  String get offlineMapTabNew;

  /// No description provided for @offlineMapTabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks & Downloaded'**
  String get offlineMapTabTasks;

  /// No description provided for @offlineMapLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading offline map data...'**
  String get offlineMapLoadingData;

  /// No description provided for @offlineMapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String offlineMapLoadFailed(Object error);

  /// No description provided for @offlineMapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get offlineMapSearchHint;

  /// No description provided for @offlineMapSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get offlineMapSearchButton;

  /// No description provided for @offlineMapSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get offlineMapSearching;

  /// No description provided for @offlineMapNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get offlineMapNoResults;

  /// No description provided for @offlineMapDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get offlineMapDownloadAction;

  /// No description provided for @offlineMapStatusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String offlineMapStatusDownloading(Object percent);

  /// No description provided for @offlineMapStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get offlineMapStatusCompleted;

  /// No description provided for @offlineMapStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get offlineMapStatusFailed;

  /// No description provided for @offlineMapStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get offlineMapStatusPaused;

  /// No description provided for @offlineMapStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get offlineMapStatusCanceled;

  /// No description provided for @offlineMapStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending...'**
  String get offlineMapStatusPending;

  /// No description provided for @offlineMapPauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get offlineMapPauseAction;

  /// No description provided for @offlineMapResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get offlineMapResumeAction;

  /// No description provided for @offlineMapDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get offlineMapDeleteAction;

  /// No description provided for @offlineMapNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get offlineMapNoTasks;

  /// No description provided for @reminderNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get reminderNameRequired;

  /// No description provided for @reminderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String reminderSaveFailed(Object error);

  /// No description provided for @reminderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get reminderDetailTitle;

  /// No description provided for @reminderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get reminderNameLabel;

  /// No description provided for @reminderNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Supermarket, Office'**
  String get reminderNameHint;

  /// No description provided for @reminderRadiusText.
  ///
  /// In en, this message translates to:
  /// **'Reminder radius: {radius} meters'**
  String reminderRadiusText(int radius);

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @reminderListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reminders'**
  String get reminderListTitle;

  /// No description provided for @reminderListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get reminderListEmpty;

  /// No description provided for @reminderListItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Radius: {radius}m\nCoordinates: {lat}, {lon}'**
  String reminderListItemSubtitle(int radius, Object lat, Object lon);

  /// No description provided for @reminderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Add/Edit Reminder'**
  String get reminderEditTitle;

  /// No description provided for @reminderDetailInfo.
  ///
  /// In en, this message translates to:
  /// **'Latitude: {lat}\nLontitude: {lon}'**
  String reminderDetailInfo(Object lat, Object lon);

  /// No description provided for @reminderCreated.
  ///
  /// In en, this message translates to:
  /// **'Reminder created'**
  String get reminderCreated;

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated'**
  String get reminderUpdated;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @backgroundServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Triggeo Background Detection'**
  String get backgroundServiceTitle;

  /// No description provided for @backgroundServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Background location detection running...'**
  String get backgroundServiceContent;

  /// No description provided for @backgroundServicePermissionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to start background service. Please ensure location permission is granted.'**
  String get backgroundServicePermissionError;

  /// No description provided for @backgroundServiceAlwaysPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Insufficient location permission. Please grant \"Always\" permission in system settings to ensure background reminder functionality.'**
  String get backgroundServiceAlwaysPermissionError;

  /// No description provided for @backgroundServiceStarted.
  ///
  /// In en, this message translates to:
  /// **'Background location service started'**
  String get backgroundServiceStarted;

  /// No description provided for @backgroundServiceStopped.
  ///
  /// In en, this message translates to:
  /// **'Background location service stopped'**
  String get backgroundServiceStopped;

  /// No description provided for @locationServiceAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Triggered: {name}'**
  String locationServiceAlertTitle(Object name);

  /// No description provided for @locationServiceAlertBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'📍 Arrival Alert: {name}'**
  String locationServiceAlertBodyTitle(Object name);

  /// No description provided for @locationServiceAlertBodySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at Target Location'**
  String get locationServiceAlertBodySubtitle;

  /// No description provided for @notificationChannelBackgroundName.
  ///
  /// In en, this message translates to:
  /// **'Background Running Service'**
  String get notificationChannelBackgroundName;

  /// No description provided for @notificationChannelBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep app running in background to detect location'**
  String get notificationChannelBackgroundDesc;

  /// No description provided for @notificationChannelAlertName.
  ///
  /// In en, this message translates to:
  /// **'Location Arrival Reminder'**
  String get notificationChannelAlertName;

  /// No description provided for @notificationChannelAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify when arriving at a destination'**
  String get notificationChannelAlertDesc;

  /// No description provided for @notificationChannelDownloadName.
  ///
  /// In en, this message translates to:
  /// **'Map Download Progress'**
  String get notificationChannelDownloadName;

  /// No description provided for @notificationChannelDownloadDesc.
  ///
  /// In en, this message translates to:
  /// **'Show progress of offline map downloads'**
  String get notificationChannelDownloadDesc;

  /// No description provided for @notificationDownloadProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading offline map ({activeTasks} tasks)'**
  String notificationDownloadProgressTitle(int activeTasks);

  /// No description provided for @notificationDownloadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String notificationDownloadFailedTitle(Object error);

  /// No description provided for @notificationDownloadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please check network and try again'**
  String get notificationDownloadFailedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
