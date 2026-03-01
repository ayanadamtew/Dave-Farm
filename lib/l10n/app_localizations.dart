import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

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
    Locale('am'),
    Locale('en'),
    Locale('om'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Dave Farm'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navFlocks.
  ///
  /// In en, this message translates to:
  /// **'Flocks'**
  String get navFlocks;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Daily Logs'**
  String get navLogs;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Egg Sales'**
  String get navSales;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get btnGenerateReport;

  /// No description provided for @btnLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get btnLogin;

  /// No description provided for @btnRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get btnRegister;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldFarmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get fieldFarmName;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get fieldBreed;

  /// No description provided for @fieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get fieldStartDate;

  /// No description provided for @fieldInitialCount.
  ///
  /// In en, this message translates to:
  /// **'Initial Bird Count'**
  String get fieldInitialCount;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldFlock.
  ///
  /// In en, this message translates to:
  /// **'Flock'**
  String get fieldFlock;

  /// No description provided for @fieldGoodEggs.
  ///
  /// In en, this message translates to:
  /// **'Good Eggs'**
  String get fieldGoodEggs;

  /// No description provided for @fieldBrokenEggs.
  ///
  /// In en, this message translates to:
  /// **'Broken Eggs'**
  String get fieldBrokenEggs;

  /// No description provided for @fieldDeadBirds.
  ///
  /// In en, this message translates to:
  /// **'Dead Birds'**
  String get fieldDeadBirds;

  /// No description provided for @fieldCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get fieldCustomerName;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @fieldUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get fieldUnitPrice;

  /// No description provided for @fieldTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get fieldTotalPrice;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get fieldNotes;

  /// No description provided for @categoryLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get categoryLabor;

  /// No description provided for @categoryHouseRent.
  ///
  /// In en, this message translates to:
  /// **'House Rent'**
  String get categoryHouseRent;

  /// No description provided for @labelLayingPercentage.
  ///
  /// In en, this message translates to:
  /// **'Laying %'**
  String get labelLayingPercentage;

  /// No description provided for @labelCostPerEgg.
  ///
  /// In en, this message translates to:
  /// **'Cost per Egg'**
  String get labelCostPerEgg;

  /// No description provided for @labelNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get labelNetProfit;

  /// No description provided for @labelTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get labelTotalSales;

  /// No description provided for @labelTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get labelTotalExpenses;

  /// No description provided for @labelCurrentBirds.
  ///
  /// In en, this message translates to:
  /// **'Current Birds'**
  String get labelCurrentBirds;

  /// No description provided for @labelTotalFlocks.
  ///
  /// In en, this message translates to:
  /// **'Active Flocks'**
  String get labelTotalFlocks;

  /// No description provided for @labelEggProduction.
  ///
  /// In en, this message translates to:
  /// **'Egg Production (30 days)'**
  String get labelEggProduction;

  /// No description provided for @labelNetProfitChart.
  ///
  /// In en, this message translates to:
  /// **'Net Profit (30 days)'**
  String get labelNetProfitChart;

  /// No description provided for @labelStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get labelStartDate;

  /// No description provided for @labelEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get labelEndDate;

  /// No description provided for @labelPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get labelPinTitle;

  /// No description provided for @labelSetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set 4-digit PIN'**
  String get labelSetPinTitle;

  /// No description provided for @labelConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get labelConfirmPin;

  /// No description provided for @errPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get errPinMismatch;

  /// No description provided for @errLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check credentials.'**
  String get errLoginFailed;

  /// No description provided for @errRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errRequired;

  /// No description provided for @errInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get errInvalidNumber;

  /// No description provided for @msgSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get msgSaved;

  /// No description provided for @msgDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get msgDeleted;

  /// No description provided for @msgSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing data…'**
  String get msgSyncing;

  /// No description provided for @msgSynced.
  ///
  /// In en, this message translates to:
  /// **'Data synced'**
  String get msgSynced;

  /// No description provided for @msgOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — data will sync when connected'**
  String get msgOffline;

  /// No description provided for @msgNoPdfApp.
  ///
  /// In en, this message translates to:
  /// **'No PDF viewer found on device'**
  String get msgNoPdfApp;

  /// No description provided for @titleAddFlock.
  ///
  /// In en, this message translates to:
  /// **'Add Flock'**
  String get titleAddFlock;

  /// No description provided for @titleEditFlock.
  ///
  /// In en, this message translates to:
  /// **'Edit Flock'**
  String get titleEditFlock;

  /// No description provided for @titleDailyLog.
  ///
  /// In en, this message translates to:
  /// **'Daily Log'**
  String get titleDailyLog;

  /// No description provided for @titleEggSale.
  ///
  /// In en, this message translates to:
  /// **'Egg Sale'**
  String get titleEggSale;

  /// No description provided for @titleExpense.
  ///
  /// In en, this message translates to:
  /// **'Log Expense'**
  String get titleExpense;

  /// No description provided for @titleReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get titleReport;

  /// No description provided for @titleLogin.
  ///
  /// In en, this message translates to:
  /// **'Login to Dave Farm'**
  String get titleLogin;

  /// No description provided for @titleRegister.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get titleRegister;
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
      <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
