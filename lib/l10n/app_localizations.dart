import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'L10n/app_localizations.dart';
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
    Locale('id'),
  ];

  /// No description provided for @plantStatus.
  ///
  /// In en, this message translates to:
  /// **'Plant Status:'**
  String get plantStatus;

  /// No description provided for @healthyGrowing.
  ///
  /// In en, this message translates to:
  /// **'Healthy & Growing'**
  String get healthyGrowing;

  /// No description provided for @scanPlant.
  ///
  /// In en, this message translates to:
  /// **'Scan Plant'**
  String get scanPlant;

  /// No description provided for @scanPlantDesc.
  ///
  /// In en, this message translates to:
  /// **'Open camera to detect chili disease'**
  String get scanPlantDesc;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get taskList;

  /// No description provided for @taskListDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage daily care plan'**
  String get taskListDesc;

  /// No description provided for @plantHealth.
  ///
  /// In en, this message translates to:
  /// **'Plant Health'**
  String get plantHealth;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs immediate attention'**
  String get needsAttention;

  /// No description provided for @accuracyLevel.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY LEVEL: 92%'**
  String get accuracyLevel;

  /// No description provided for @criticalArea.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL AREA: BLOCK B'**
  String get criticalArea;

  /// No description provided for @todayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todayTasks;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @recentStatus.
  ///
  /// In en, this message translates to:
  /// **'Recent Status'**
  String get recentStatus;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get healthy;

  /// No description provided for @infected.
  ///
  /// In en, this message translates to:
  /// **'INFECTED'**
  String get infected;

  /// No description provided for @noScansYet.
  ///
  /// In en, this message translates to:
  /// **'No scans yet'**
  String get noScansYet;

  /// No description provided for @diagnosisHistory.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis History'**
  String get diagnosisHistory;

  /// No description provided for @dailyTasks.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get dailyTasks;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// No description provided for @sprayFungicide.
  ///
  /// In en, this message translates to:
  /// **'Spray Fungicide'**
  String get sprayFungicide;

  /// No description provided for @urgentDesc.
  ///
  /// In en, this message translates to:
  /// **'Infection detected in Sector 4.\nSpray immediately to prevent\nspread to Area C.'**
  String get urgentDesc;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @noDailyPhoto.
  ///
  /// In en, this message translates to:
  /// **'No daily diagnosis photo yet'**
  String get noDailyPhoto;

  /// No description provided for @statusOverview.
  ///
  /// In en, this message translates to:
  /// **'Status Overview'**
  String get statusOverview;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @tasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksLabel;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'ALL TASKS'**
  String get allTasks;

  /// No description provided for @next3Days.
  ///
  /// In en, this message translates to:
  /// **'Next 3 Days'**
  String get next3Days;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get viewCalendar;

  /// No description provided for @checkPlants.
  ///
  /// In en, this message translates to:
  /// **'Check Plants'**
  String get checkPlants;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'APP SETTINGS'**
  String get appSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @carePlan.
  ///
  /// In en, this message translates to:
  /// **'Care Plan'**
  String get carePlan;

  /// No description provided for @carePlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly chili plant care schedule'**
  String get carePlanDesc;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @monthlyView.
  ///
  /// In en, this message translates to:
  /// **'Monthly View'**
  String get monthlyView;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @plansFor.
  ///
  /// In en, this message translates to:
  /// **'Plans for'**
  String get plansFor;

  /// No description provided for @noPlansToday.
  ///
  /// In en, this message translates to:
  /// **'No plans for today yet'**
  String get noPlansToday;

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @noDiagnosisHistory.
  ///
  /// In en, this message translates to:
  /// **'No diagnosis history yet'**
  String get noDiagnosisHistory;

  /// No description provided for @scanToStart.
  ///
  /// In en, this message translates to:
  /// **'Scan plants to get started'**
  String get scanToStart;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @treatmentSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Treatment Suggestions'**
  String get treatmentSuggestions;

  /// No description provided for @analyzingPlant.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Plant...'**
  String get analyzingPlant;

  /// No description provided for @diagnosisResult.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get diagnosisResult;

  /// No description provided for @aiDetecting.
  ///
  /// In en, this message translates to:
  /// **'ChiliCare AI is detecting...'**
  String get aiDetecting;

  /// No description provided for @addToTasks.
  ///
  /// In en, this message translates to:
  /// **'Add to Tasks'**
  String get addToTasks;

  /// No description provided for @frontCamera.
  ///
  /// In en, this message translates to:
  /// **'Front camera'**
  String get frontCamera;

  /// No description provided for @diagnosisSaved.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis saved & task added!'**
  String get diagnosisSaved;

  /// No description provided for @cercosporaLeafSpot.
  ///
  /// In en, this message translates to:
  /// **'Cercospora Leaf Spot'**
  String get cercosporaLeafSpot;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get indonesian;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'IriGrow v2.4.0-Stable'**
  String get version;

  /// No description provided for @designedFor.
  ///
  /// In en, this message translates to:
  /// **'Designed for the Best\nPrecision Agriculture'**
  String get designedFor;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get percentComplete;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeNav;

  /// No description provided for @tasksNav.
  ///
  /// In en, this message translates to:
  /// **'TASKS'**
  String get tasksNav;

  /// No description provided for @careNav.
  ///
  /// In en, this message translates to:
  /// **'CARE'**
  String get careNav;

  /// No description provided for @settingsNav.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsNav;

  /// No description provided for @treatmentFull.
  ///
  /// In en, this message translates to:
  /// **'1. Immediately prune infected brown-spotted leaves.\n2. Spray Mancozeb-based fungicide in the morning.\n3. Reduce humidity by spacing plants further apart.'**
  String get treatmentFull;

  /// No description provided for @reviewCercospora.
  ///
  /// In en, this message translates to:
  /// **'Review Cercospora Leaf Spot'**
  String get reviewCercospora;

  /// No description provided for @pruneAndSpray.
  ///
  /// In en, this message translates to:
  /// **'Prune leaves & spray Mancozeb fungicide'**
  String get pruneAndSpray;

  /// No description provided for @sprayMancozeb.
  ///
  /// In en, this message translates to:
  /// **'Spray Mancozeb fungicide & prune infected leaves'**
  String get sprayMancozeb;

  /// No description provided for @monthlyViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly View'**
  String get monthlyViewTitle;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'MONDAY'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'TUESDAY'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'WEDNESDAY'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'THURSDAY'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'FRIDAY'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'SATURDAY'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'SUNDAY'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'JANUARY'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'FEBRUARY'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'MARCH'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'APRIL'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'JUNE'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'JULY'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'AUGUST'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'SEPTEMBER'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'OCTOBER'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'NOVEMBER'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'DECEMBER'**
  String get december;

  /// No description provided for @janShort.
  ///
  /// In en, this message translates to:
  /// **'JAN'**
  String get janShort;

  /// No description provided for @febShort.
  ///
  /// In en, this message translates to:
  /// **'FEB'**
  String get febShort;

  /// No description provided for @marShort.
  ///
  /// In en, this message translates to:
  /// **'MAR'**
  String get marShort;

  /// No description provided for @aprShort.
  ///
  /// In en, this message translates to:
  /// **'APR'**
  String get aprShort;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'MAY'**
  String get mayShort;

  /// No description provided for @junShort.
  ///
  /// In en, this message translates to:
  /// **'JUN'**
  String get junShort;

  /// No description provided for @julShort.
  ///
  /// In en, this message translates to:
  /// **'JUL'**
  String get julShort;

  /// No description provided for @augShort.
  ///
  /// In en, this message translates to:
  /// **'AUG'**
  String get augShort;

  /// No description provided for @sepShort.
  ///
  /// In en, this message translates to:
  /// **'SEP'**
  String get sepShort;

  /// No description provided for @octShort.
  ///
  /// In en, this message translates to:
  /// **'OCT'**
  String get octShort;

  /// No description provided for @novShort.
  ///
  /// In en, this message translates to:
  /// **'NOV'**
  String get novShort;

  /// No description provided for @decShort.
  ///
  /// In en, this message translates to:
  /// **'DEC'**
  String get decShort;

  /// No description provided for @januaryFull.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get januaryFull;

  /// No description provided for @februaryFull.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get februaryFull;

  /// No description provided for @marchFull.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get marchFull;

  /// No description provided for @aprilFull.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get aprilFull;

  /// No description provided for @mayFull.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayFull;

  /// No description provided for @juneFull.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get juneFull;

  /// No description provided for @julyFull.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get julyFull;

  /// No description provided for @augustFull.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get augustFull;

  /// No description provided for @septemberFull.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get septemberFull;

  /// No description provided for @octoberFull.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get octoberFull;

  /// No description provided for @novemberFull.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get novemberFull;

  /// No description provided for @decemberFull.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get decemberFull;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
