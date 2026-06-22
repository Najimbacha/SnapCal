import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'SnapCal'**
  String get appTitle;

  /// No description provided for @ads_label.
  ///
  /// In en, this message translates to:
  /// **'ADVERTISEMENT'**
  String get ads_label;

  /// No description provided for @ads_remove_prompt.
  ///
  /// In en, this message translates to:
  /// **'Remove ads — Go Pro'**
  String get ads_remove_prompt;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_offline_mode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get common_offline_mode;

  /// No description provided for @error_scan_failed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed. Please try again or enter manually.'**
  String get error_scan_failed;

  /// No description provided for @error_barcode_not_found.
  ///
  /// In en, this message translates to:
  /// **'Product not found. Please try manual entry.'**
  String get error_barcode_not_found;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get nav_log;

  /// No description provided for @nav_stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get nav_stats;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @home_greeting_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get home_greeting_morning;

  /// No description provided for @home_greeting_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get home_greeting_afternoon;

  /// No description provided for @home_greeting_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get home_greeting_evening;

  /// No description provided for @home_calories_remaining.
  ///
  /// In en, this message translates to:
  /// **'Calories remaining'**
  String get home_calories_remaining;

  /// No description provided for @home_calories_eaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get home_calories_eaten;

  /// No description provided for @home_calories_burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get home_calories_burned;

  /// No description provided for @home_water_title.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get home_water_title;

  /// No description provided for @home_water_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal}ml'**
  String home_water_goal(int goal);

  /// No description provided for @home_recent_meals.
  ///
  /// In en, this message translates to:
  /// **'Recent Meals'**
  String get home_recent_meals;

  /// No description provided for @home_view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get home_view_all;

  /// No description provided for @home_streak_days.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String home_streak_days(int count);

  /// No description provided for @home_section_macros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get home_section_macros;

  /// No description provided for @home_section_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get home_section_actions;

  /// No description provided for @home_action_log.
  ///
  /// In en, this message translates to:
  /// **'Open log'**
  String get home_action_log;

  /// No description provided for @home_action_reports.
  ///
  /// In en, this message translates to:
  /// **'See reports'**
  String get home_action_reports;

  /// No description provided for @home_sync_prompt.
  ///
  /// In en, this message translates to:
  /// **'Create an account to sync your progress.'**
  String get home_sync_prompt;

  /// No description provided for @log_title.
  ///
  /// In en, this message translates to:
  /// **'Daily Log'**
  String get log_title;

  /// No description provided for @log_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your nutrition journey'**
  String get log_subtitle;

  /// No description provided for @log_entries.
  ///
  /// In en, this message translates to:
  /// **'ENTRIES'**
  String get log_entries;

  /// No description provided for @log_total_kcal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL KCAL'**
  String get log_total_kcal;

  /// No description provided for @log_history.
  ///
  /// In en, this message translates to:
  /// **'MEAL HISTORY'**
  String get log_history;

  /// No description provided for @log_no_entries_today.
  ///
  /// In en, this message translates to:
  /// **'No logs today'**
  String get log_no_entries_today;

  /// No description provided for @log_no_entries_history.
  ///
  /// In en, this message translates to:
  /// **'Empty history'**
  String get log_no_entries_history;

  /// No description provided for @log_track_prompt.
  ///
  /// In en, this message translates to:
  /// **'Track your meals to see them here.'**
  String get log_track_prompt;

  /// No description provided for @log_no_data_prompt.
  ///
  /// In en, this message translates to:
  /// **'There is no data for this day.'**
  String get log_no_data_prompt;

  /// No description provided for @log_return_today.
  ///
  /// In en, this message translates to:
  /// **'Return to Today'**
  String get log_return_today;

  /// No description provided for @log_add_manually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get log_add_manually;

  /// No description provided for @log_removed_snackbar.
  ///
  /// In en, this message translates to:
  /// **'{food} removed'**
  String log_removed_snackbar(String food);

  /// No description provided for @assistant_title.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get assistant_title;

  /// No description provided for @assistant_status.
  ///
  /// In en, this message translates to:
  /// **'Always active'**
  String get assistant_status;

  /// No description provided for @assistant_initial_prompt.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get assistant_initial_prompt;

  /// No description provided for @assistant_initial_body.
  ///
  /// In en, this message translates to:
  /// **'Your personal SnapCal coach is ready to assist with recipes, goals, and nutrition advice.'**
  String get assistant_initial_body;

  /// No description provided for @assistant_preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your wellness journey...'**
  String get assistant_preparing;

  /// No description provided for @assistant_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get assistant_input_hint;

  /// No description provided for @assistant_input_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get assistant_input_listening;

  /// No description provided for @assistant_needs_connection.
  ///
  /// In en, this message translates to:
  /// **'Assistant needs connection.'**
  String get assistant_needs_connection;

  /// No description provided for @assistant_clear_title.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat?'**
  String get assistant_clear_title;

  /// No description provided for @assistant_clear_body.
  ///
  /// In en, this message translates to:
  /// **'This will delete your conversation history with the coach.'**
  String get assistant_clear_body;

  /// No description provided for @assistant_clear_confirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get assistant_clear_confirm;

  /// No description provided for @assistant_starter_meal_title.
  ///
  /// In en, this message translates to:
  /// **'Meal Ideas'**
  String get assistant_starter_meal_title;

  /// No description provided for @assistant_starter_meal_desc.
  ///
  /// In en, this message translates to:
  /// **'High-protein dinners'**
  String get assistant_starter_meal_desc;

  /// No description provided for @assistant_starter_cal_title.
  ///
  /// In en, this message translates to:
  /// **'Calorie Check'**
  String get assistant_starter_cal_title;

  /// No description provided for @assistant_starter_cal_desc.
  ///
  /// In en, this message translates to:
  /// **'How am I doing today?'**
  String get assistant_starter_cal_desc;

  /// No description provided for @assistant_starter_tips_title.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get assistant_starter_tips_title;

  /// No description provided for @assistant_starter_tips_desc.
  ///
  /// In en, this message translates to:
  /// **'Curbing late-night cravings'**
  String get assistant_starter_tips_desc;

  /// No description provided for @assistant_starter_plans_title.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get assistant_starter_plans_title;

  /// No description provided for @assistant_starter_plans_desc.
  ///
  /// In en, this message translates to:
  /// **'Create a 3-day meal plan'**
  String get assistant_starter_plans_desc;

  /// No description provided for @premium_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SnapCal Pro! 🎉'**
  String get premium_welcome;

  /// No description provided for @premium_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Purchases Restored! 🎉'**
  String get premium_restore_success;

  /// No description provided for @premium_restore_empty.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found.'**
  String get premium_restore_empty;

  /// No description provided for @premium_restore_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore purchases.'**
  String get premium_restore_fail;

  /// No description provided for @premium_plan_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premium_plan_yearly;

  /// No description provided for @premium_plan_6months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get premium_plan_6months;

  /// No description provided for @premium_plan_3months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get premium_plan_3months;

  /// No description provided for @premium_plan_2months.
  ///
  /// In en, this message translates to:
  /// **'2 Months'**
  String get premium_plan_2months;

  /// No description provided for @premium_plan_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premium_plan_monthly;

  /// No description provided for @premium_plan_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get premium_plan_weekly;

  /// No description provided for @premium_plan_lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get premium_plan_lifetime;

  /// No description provided for @premium_per_month.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get premium_per_month;

  /// No description provided for @premium_free_trial.
  ///
  /// In en, this message translates to:
  /// **'free trial'**
  String get premium_free_trial;

  /// No description provided for @premium_start_trial.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
  String get premium_start_trial;

  /// No description provided for @premium_start_plan.
  ///
  /// In en, this message translates to:
  /// **'Start {plan} — {price}'**
  String premium_start_plan(String plan, String price);

  /// No description provided for @premium_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get premium_loading;

  /// No description provided for @snap_align_food.
  ///
  /// In en, this message translates to:
  /// **'Align food in the frame'**
  String get snap_align_food;

  /// No description provided for @snap_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal...'**
  String get snap_analyzing;

  /// No description provided for @snap_retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get snap_retake;

  /// No description provided for @snap_log_meal.
  ///
  /// In en, this message translates to:
  /// **'Log this meal'**
  String get snap_log_meal;

  /// No description provided for @result_energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get result_energy;

  /// No description provided for @result_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get result_protein;

  /// No description provided for @result_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get result_carbs;

  /// No description provided for @result_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get result_fat;

  /// No description provided for @result_portion.
  ///
  /// In en, this message translates to:
  /// **'Portion Size'**
  String get result_portion;

  /// No description provided for @result_save_success.
  ///
  /// In en, this message translates to:
  /// **'Meal logged successfully!'**
  String get result_save_success;

  /// No description provided for @result_health.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get result_health;

  /// No description provided for @result_kcal.
  ///
  /// In en, this message translates to:
  /// **'KCAL'**
  String get result_kcal;

  /// No description provided for @result_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get result_calories;

  /// No description provided for @result_macronutrients.
  ///
  /// In en, this message translates to:
  /// **'MACRONUTRIENTS'**
  String get result_macronutrients;

  /// No description provided for @result_logging_portion.
  ///
  /// In en, this message translates to:
  /// **'LOGGING PORTION'**
  String get result_logging_portion;

  /// No description provided for @result_ai_estimate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of AI estimate'**
  String result_ai_estimate(int percent);

  /// No description provided for @result_daily_goal_info.
  ///
  /// In en, this message translates to:
  /// **'This meal is {percent}% of your daily energy goal.'**
  String result_daily_goal_info(int percent);

  /// No description provided for @planner_title.
  ///
  /// In en, this message translates to:
  /// **'Meal Planner'**
  String get planner_title;

  /// No description provided for @planner_smart_title.
  ///
  /// In en, this message translates to:
  /// **'Smart Planner'**
  String get planner_smart_title;

  /// No description provided for @planner_empty_state.
  ///
  /// In en, this message translates to:
  /// **'No plan for today'**
  String get planner_empty_state;

  /// No description provided for @planner_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate AI Plan'**
  String get planner_generate;

  /// No description provided for @planner_daily_goal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get planner_daily_goal;

  /// No description provided for @planner_tab_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly Plan'**
  String get planner_tab_weekly;

  /// No description provided for @planner_tab_grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery List'**
  String get planner_tab_grocery;

  /// No description provided for @planner_day_mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get planner_day_mon;

  /// No description provided for @planner_day_tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get planner_day_tue;

  /// No description provided for @planner_day_wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get planner_day_wed;

  /// No description provided for @planner_day_thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get planner_day_thu;

  /// No description provided for @planner_day_fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get planner_day_fri;

  /// No description provided for @planner_day_sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get planner_day_sat;

  /// No description provided for @planner_day_sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get planner_day_sun;

  /// No description provided for @planner_no_meals.
  ///
  /// In en, this message translates to:
  /// **'No meals for {day}'**
  String planner_no_meals(Object day);

  /// No description provided for @planner_regenerate_day.
  ///
  /// In en, this message translates to:
  /// **'Regenerate {day}?'**
  String planner_regenerate_day(Object day);

  /// No description provided for @planner_grocery_empty.
  ///
  /// In en, this message translates to:
  /// **'No grocery list yet'**
  String get planner_grocery_empty;

  /// No description provided for @planner_grocery_pro.
  ///
  /// In en, this message translates to:
  /// **'Grocery list is Pro'**
  String get planner_grocery_pro;

  /// No description provided for @planner_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get planner_share;

  /// No description provided for @planner_creating.
  ///
  /// In en, this message translates to:
  /// **'Creating your plan'**
  String get planner_creating;

  /// No description provided for @planner_msg_calories.
  ///
  /// In en, this message translates to:
  /// **'Calculating your calorie needs...'**
  String get planner_msg_calories;

  /// No description provided for @planner_msg_meals.
  ///
  /// In en, this message translates to:
  /// **'Picking the best meals for your goal...'**
  String get planner_msg_meals;

  /// No description provided for @planner_msg_macros.
  ///
  /// In en, this message translates to:
  /// **'Balancing your macros...'**
  String get planner_msg_macros;

  /// No description provided for @planner_msg_grocery.
  ///
  /// In en, this message translates to:
  /// **'Building your grocery list...'**
  String get planner_msg_grocery;

  /// No description provided for @planner_msg_ready.
  ///
  /// In en, this message translates to:
  /// **'Almost ready...'**
  String get planner_msg_ready;

  /// No description provided for @error_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline: AI analysis unavailable'**
  String get error_offline;

  /// No description provided for @error_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get error_camera;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error_generic;

  /// No description provided for @sync_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get sync_title;

  /// No description provided for @sync_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your health data safe across all your devices with an account.'**
  String get sync_subtitle;

  /// No description provided for @sync_benefit_devices.
  ///
  /// In en, this message translates to:
  /// **'Sync across all your devices'**
  String get sync_benefit_devices;

  /// No description provided for @sync_benefit_progress.
  ///
  /// In en, this message translates to:
  /// **'Never lose your progress'**
  String get sync_benefit_progress;

  /// No description provided for @sync_benefit_offline.
  ///
  /// In en, this message translates to:
  /// **'Works offline, syncs when online'**
  String get sync_benefit_offline;

  /// No description provided for @sync_benefit_secure.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted & secure'**
  String get sync_benefit_secure;

  /// No description provided for @sync_google.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get sync_google;

  /// No description provided for @sync_facebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get sync_facebook;

  /// No description provided for @sync_email.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get sync_email;

  /// No description provided for @sync_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get sync_skip;

  /// No description provided for @splash_tagline.
  ///
  /// In en, this message translates to:
  /// **'Snap. Track. Thrive.'**
  String get splash_tagline;

  /// No description provided for @notif_breakfast_title.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Reminder'**
  String get notif_breakfast_title;

  /// No description provided for @notif_breakfast_body.
  ///
  /// In en, this message translates to:
  /// **'Time to log your healthy breakfast!'**
  String get notif_breakfast_body;

  /// No description provided for @notif_lunch_title.
  ///
  /// In en, this message translates to:
  /// **'Lunch Reminder'**
  String get notif_lunch_title;

  /// No description provided for @notif_lunch_body.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to track your lunch.'**
  String get notif_lunch_body;

  /// No description provided for @notif_dinner_title.
  ///
  /// In en, this message translates to:
  /// **'Dinner Reminder'**
  String get notif_dinner_title;

  /// No description provided for @notif_dinner_body.
  ///
  /// In en, this message translates to:
  /// **'End the day strong—log your dinner now.'**
  String get notif_dinner_body;

  /// No description provided for @notif_meal_reminders_channel.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get notif_meal_reminders_channel;

  /// No description provided for @notif_meal_reminders_channel_description.
  ///
  /// In en, this message translates to:
  /// **'Reminders to log your daily nutrition.'**
  String get notif_meal_reminders_channel_description;

  /// No description provided for @notif_daily_motivation_channel.
  ///
  /// In en, this message translates to:
  /// **'Daily Motivation'**
  String get notif_daily_motivation_channel;

  /// No description provided for @notif_daily_motivation_channel_description.
  ///
  /// In en, this message translates to:
  /// **'Gentle daily nutrition motivation from SnapCal.'**
  String get notif_daily_motivation_channel_description;

  /// No description provided for @notif_motivation_1_title.
  ///
  /// In en, this message translates to:
  /// **'Small steps count'**
  String get notif_motivation_1_title;

  /// No description provided for @notif_motivation_1_body.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal when you’re ready.'**
  String get notif_motivation_1_body;

  /// No description provided for @notif_motivation_2_title.
  ///
  /// In en, this message translates to:
  /// **'Today starts simple'**
  String get notif_motivation_2_title;

  /// No description provided for @notif_motivation_2_body.
  ///
  /// In en, this message translates to:
  /// **'Choose one meal that supports your goal.'**
  String get notif_motivation_2_body;

  /// No description provided for @notif_motivation_3_title.
  ///
  /// In en, this message translates to:
  /// **'One good choice'**
  String get notif_motivation_3_title;

  /// No description provided for @notif_motivation_3_body.
  ///
  /// In en, this message translates to:
  /// **'Start with protein, water, or a quick meal log.'**
  String get notif_motivation_3_body;

  /// No description provided for @notif_motivation_4_title.
  ///
  /// In en, this message translates to:
  /// **'You don’t need perfect'**
  String get notif_motivation_4_title;

  /// No description provided for @notif_motivation_4_body.
  ///
  /// In en, this message translates to:
  /// **'Just notice what you eat today.'**
  String get notif_motivation_4_body;

  /// No description provided for @notif_motivation_5_title.
  ///
  /// In en, this message translates to:
  /// **'Fuel first'**
  String get notif_motivation_5_title;

  /// No description provided for @notif_motivation_5_body.
  ///
  /// In en, this message translates to:
  /// **'Give your body something useful today.'**
  String get notif_motivation_5_body;

  /// No description provided for @notif_motivation_6_title.
  ///
  /// In en, this message translates to:
  /// **'Make it easy'**
  String get notif_motivation_6_title;

  /// No description provided for @notif_motivation_6_body.
  ///
  /// In en, this message translates to:
  /// **'Track one meal. That’s enough to build momentum.'**
  String get notif_motivation_6_body;

  /// No description provided for @notif_motivation_7_title.
  ///
  /// In en, this message translates to:
  /// **'Build the day well'**
  String get notif_motivation_7_title;

  /// No description provided for @notif_motivation_7_body.
  ///
  /// In en, this message translates to:
  /// **'A balanced first meal makes the next choice easier.'**
  String get notif_motivation_7_body;

  /// No description provided for @notif_motivation_8_title.
  ///
  /// In en, this message translates to:
  /// **'Your health is daily'**
  String get notif_motivation_8_title;

  /// No description provided for @notif_motivation_8_body.
  ///
  /// In en, this message translates to:
  /// **'A small check-in keeps you in control.'**
  String get notif_motivation_8_body;

  /// No description provided for @auth_title.
  ///
  /// In en, this message translates to:
  /// **'Your Journey\nStarts Here'**
  String get auth_title;

  /// No description provided for @auth_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan, Track, and Master your nutrition in seconds.'**
  String get auth_subtitle;

  /// No description provided for @auth_divider_email.
  ///
  /// In en, this message translates to:
  /// **'Or use email'**
  String get auth_divider_email;

  /// No description provided for @auth_hint_email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_hint_email;

  /// No description provided for @auth_hint_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_hint_password;

  /// No description provided for @auth_btn_signup.
  ///
  /// In en, this message translates to:
  /// **'Create My Account'**
  String get auth_btn_signup;

  /// No description provided for @auth_btn_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get auth_btn_signin;

  /// No description provided for @auth_footer_member.
  ///
  /// In en, this message translates to:
  /// **'Already a member? '**
  String get auth_footer_member;

  /// No description provided for @auth_footer_new.
  ///
  /// In en, this message translates to:
  /// **'New to SnapCal? '**
  String get auth_footer_new;

  /// No description provided for @auth_action_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_action_signin;

  /// No description provided for @auth_action_join.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get auth_action_join;

  /// No description provided for @auth_msg_success.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get auth_msg_success;

  /// No description provided for @auth_msg_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String auth_msg_welcome(String name);

  /// No description provided for @result_meal_breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get result_meal_breakfast;

  /// No description provided for @result_meal_lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get result_meal_lunch;

  /// No description provided for @result_meal_dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get result_meal_dinner;

  /// No description provided for @result_meal_snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get result_meal_snack;

  /// No description provided for @result_macro_power.
  ///
  /// In en, this message translates to:
  /// **'POWER'**
  String get result_macro_power;

  /// No description provided for @result_macro_energy.
  ///
  /// In en, this message translates to:
  /// **'ENERGY'**
  String get result_macro_energy;

  /// No description provided for @result_macro_lean.
  ///
  /// In en, this message translates to:
  /// **'LEAN'**
  String get result_macro_lean;

  /// No description provided for @common_hero.
  ///
  /// In en, this message translates to:
  /// **'HERO'**
  String get common_hero;

  /// No description provided for @notif_goal_calories_title.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached! 🚀'**
  String get notif_goal_calories_title;

  /// No description provided for @notif_goal_calories_body.
  ///
  /// In en, this message translates to:
  /// **'You\'ve hit your daily calorie goal of {goal} kcal!'**
  String notif_goal_calories_body(Object goal);

  /// No description provided for @notif_goal_protein_title.
  ///
  /// In en, this message translates to:
  /// **'Protein Goal Met! 💪'**
  String get notif_goal_protein_title;

  /// No description provided for @notif_goal_protein_body.
  ///
  /// In en, this message translates to:
  /// **'Great job! You\'ve reached your {goal}g protein target.'**
  String notif_goal_protein_body(Object goal);

  /// No description provided for @notif_goal_alerts_channel.
  ///
  /// In en, this message translates to:
  /// **'Goal alerts'**
  String get notif_goal_alerts_channel;

  /// No description provided for @notif_goal_alerts_channel_description.
  ///
  /// In en, this message translates to:
  /// **'Alerts when you hit your nutrition milestones.'**
  String get notif_goal_alerts_channel_description;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_save_progress.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get common_save_progress;

  /// No description provided for @common_delete_permanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get common_delete_permanently;

  /// No description provided for @common_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get common_try_again;

  /// No description provided for @common_try_reload.
  ///
  /// In en, this message translates to:
  /// **'Try to Reload'**
  String get common_try_reload;

  /// No description provided for @common_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get common_sign_out;

  /// No description provided for @common_sign_out_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get common_sign_out_confirm;

  /// No description provided for @common_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get common_delete_account;

  /// No description provided for @common_delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. All your data will be lost.'**
  String get common_delete_account_confirm;

  /// No description provided for @settings_save_name.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get settings_save_name;

  /// No description provided for @settings_log_weight_first.
  ///
  /// In en, this message translates to:
  /// **'Log your weight first to recalculate.'**
  String get settings_log_weight_first;

  /// No description provided for @settings_complete_profile_first.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile first (age, gender, height, target).'**
  String get settings_complete_profile_first;

  /// No description provided for @settings_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get settings_age;

  /// No description provided for @settings_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get settings_gender;

  /// No description provided for @settings_units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settings_units;

  /// No description provided for @settings_weight_unit.
  ///
  /// In en, this message translates to:
  /// **'Weight Unit'**
  String get settings_weight_unit;

  /// No description provided for @settings_height_unit.
  ///
  /// In en, this message translates to:
  /// **'Height Unit'**
  String get settings_height_unit;

  /// No description provided for @settings_breakfast_time.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Reminder'**
  String get settings_breakfast_time;

  /// No description provided for @settings_lunch_time.
  ///
  /// In en, this message translates to:
  /// **'Lunch Reminder'**
  String get settings_lunch_time;

  /// No description provided for @settings_dinner_time.
  ///
  /// In en, this message translates to:
  /// **'Dinner Reminder'**
  String get settings_dinner_time;

  /// No description provided for @planner_unlock_week.
  ///
  /// In en, this message translates to:
  /// **'Unlock full week'**
  String get planner_unlock_week;

  /// No description provided for @planner_upgrade_pro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get planner_upgrade_pro;

  /// No description provided for @planner_regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get planner_regenerate;

  /// No description provided for @planner_meal_preferences.
  ///
  /// In en, this message translates to:
  /// **'Meal Preferences'**
  String get planner_meal_preferences;

  /// No description provided for @planner_meals_per_day.
  ///
  /// In en, this message translates to:
  /// **'Meals per day'**
  String get planner_meals_per_day;

  /// No description provided for @planner_dietary_restriction.
  ///
  /// In en, this message translates to:
  /// **'Dietary restriction'**
  String get planner_dietary_restriction;

  /// No description provided for @planner_cuisine_style.
  ///
  /// In en, this message translates to:
  /// **'Cuisine style'**
  String get planner_cuisine_style;

  /// No description provided for @planner_generate_plan.
  ///
  /// In en, this message translates to:
  /// **'Generate My Plan'**
  String get planner_generate_plan;

  /// No description provided for @assistant_mic_permission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice input.'**
  String get assistant_mic_permission;

  /// No description provided for @assistant_added_to_diary.
  ///
  /// In en, this message translates to:
  /// **'Added to your diary! 🍎'**
  String get assistant_added_to_diary;

  /// No description provided for @assistant_plan_updated.
  ///
  /// In en, this message translates to:
  /// **'Plan updated: {key} is now {value}'**
  String assistant_plan_updated(String key, String value);

  /// No description provided for @water_add_water.
  ///
  /// In en, this message translates to:
  /// **'Add Water'**
  String get water_add_water;

  /// No description provided for @water_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get water_add;

  /// No description provided for @water_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get water_remove;

  /// No description provided for @water_hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get water_hydration;

  /// No description provided for @water_tracker.
  ///
  /// In en, this message translates to:
  /// **'Hydration Tracker'**
  String get water_tracker;

  /// No description provided for @water_reached.
  ///
  /// In en, this message translates to:
  /// **'{amount} of {goal} ml reached'**
  String water_reached(int amount, int goal);

  /// No description provided for @water_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get water_custom;

  /// No description provided for @water_enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get water_enter_amount;

  /// No description provided for @progress_tap_to_snap.
  ///
  /// In en, this message translates to:
  /// **'Tap to snap'**
  String get progress_tap_to_snap;

  /// No description provided for @progress_compare_previous.
  ///
  /// In en, this message translates to:
  /// **'Compare with previous'**
  String get progress_compare_previous;

  /// No description provided for @log_delete_meal_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Meal Entry?'**
  String get log_delete_meal_title;

  /// No description provided for @log_delete_meal_body.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this meal from your diary.'**
  String get log_delete_meal_body;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_display_name.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get settings_display_name;

  /// No description provided for @settings_how_to_call.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get settings_how_to_call;

  /// No description provided for @settings_enter_value.
  ///
  /// In en, this message translates to:
  /// **'Enter your {title} below'**
  String settings_enter_value(String title);

  /// No description provided for @settings_core_config.
  ///
  /// In en, this message translates to:
  /// **'Core Configuration'**
  String get settings_core_config;

  /// No description provided for @settings_data_security.
  ///
  /// In en, this message translates to:
  /// **'Data & Security'**
  String get settings_data_security;

  /// No description provided for @settings_information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settings_information;

  /// No description provided for @settings_body_profile.
  ///
  /// In en, this message translates to:
  /// **'Body Profile'**
  String get settings_body_profile;

  /// No description provided for @settings_body_profile_sub.
  ///
  /// In en, this message translates to:
  /// **'Update your stats and goals'**
  String get settings_body_profile_sub;

  /// No description provided for @settings_nutrition_goals.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Goals'**
  String get settings_nutrition_goals;

  /// No description provided for @settings_nutrition_goals_sub.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie and macro targets'**
  String get settings_nutrition_goals_sub;

  /// No description provided for @settings_preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_preferences;

  /// No description provided for @settings_preferences_sub.
  ///
  /// In en, this message translates to:
  /// **'App theme and notification settings'**
  String get settings_preferences_sub;

  /// No description provided for @settings_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account;

  /// No description provided for @settings_account_sub.
  ///
  /// In en, this message translates to:
  /// **'Membership and profile security'**
  String get settings_account_sub;

  /// No description provided for @settings_data_sync.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get settings_data_sync;

  /// No description provided for @settings_data_sync_sub.
  ///
  /// In en, this message translates to:
  /// **'Export and cloud backup options'**
  String get settings_data_sync_sub;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_about_sub.
  ///
  /// In en, this message translates to:
  /// **'Terms, privacy, and app info'**
  String get settings_about_sub;

  /// No description provided for @report_title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get report_title;

  /// No description provided for @report_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your long-term success'**
  String get report_subtitle;

  /// No description provided for @report_tab_nutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get report_tab_nutrition;

  /// No description provided for @report_tab_body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get report_tab_body;

  /// No description provided for @report_weekly_review.
  ///
  /// In en, this message translates to:
  /// **'Weekly Review'**
  String get report_weekly_review;

  /// No description provided for @report_monthly_audit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Audit'**
  String get report_monthly_audit;

  /// No description provided for @report_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report'**
  String get report_failed;

  /// No description provided for @paywall_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SnapCal Pro! 🎉'**
  String get paywall_welcome;

  /// No description provided for @progress_log_progress.
  ///
  /// In en, this message translates to:
  /// **'Log Progress'**
  String get progress_log_progress;

  /// No description provided for @progress_take_photos_desc.
  ///
  /// In en, this message translates to:
  /// **'Take photos to track your journey.'**
  String get progress_take_photos_desc;

  /// No description provided for @progress_front_view.
  ///
  /// In en, this message translates to:
  /// **'Front View'**
  String get progress_front_view;

  /// No description provided for @progress_side_view.
  ///
  /// In en, this message translates to:
  /// **'Side View'**
  String get progress_side_view;

  /// No description provided for @progress_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get progress_saving;

  /// No description provided for @progress_save_progress.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get progress_save_progress;

  /// No description provided for @progress_comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get progress_comparison;

  /// No description provided for @progress_weight_diff.
  ///
  /// In en, this message translates to:
  /// **'{diff} kg difference'**
  String progress_weight_diff(String diff);

  /// No description provided for @progress_before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get progress_before;

  /// No description provided for @progress_after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get progress_after;

  /// No description provided for @progress_missing_photos.
  ///
  /// In en, this message translates to:
  /// **'Missing photos for comparison.'**
  String get progress_missing_photos;

  /// No description provided for @progress_front.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get progress_front;

  /// No description provided for @progress_side.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get progress_side;

  /// No description provided for @progress_failed_camera.
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera.'**
  String get progress_failed_camera;

  /// No description provided for @assistant_attached_image.
  ///
  /// In en, this message translates to:
  /// **'Attached image'**
  String get assistant_attached_image;

  /// No description provided for @home_body_stats.
  ///
  /// In en, this message translates to:
  /// **'Body Stats'**
  String get home_body_stats;

  /// No description provided for @log_edit_meal.
  ///
  /// In en, this message translates to:
  /// **'Edit Meal Entry'**
  String get log_edit_meal;

  /// No description provided for @log_log_new_meal.
  ///
  /// In en, this message translates to:
  /// **'Log New Meal'**
  String get log_log_new_meal;

  /// No description provided for @log_food_name.
  ///
  /// In en, this message translates to:
  /// **'Food Name'**
  String get log_food_name;

  /// No description provided for @log_portion_desc.
  ///
  /// In en, this message translates to:
  /// **'Portion Description'**
  String get log_portion_desc;

  /// No description provided for @log_calories_kcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get log_calories_kcal;

  /// No description provided for @log_save_entry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get log_save_entry;

  /// No description provided for @log_delete_entry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get log_delete_entry;

  /// No description provided for @log_food_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Avocado Toast'**
  String get log_food_hint;

  /// No description provided for @log_protein_g.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get log_protein_g;

  /// No description provided for @log_carbs_g.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get log_carbs_g;

  /// No description provided for @log_fat_g.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get log_fat_g;

  /// No description provided for @common_keep_it.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get common_keep_it;

  /// No description provided for @planner_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get planner_target;

  /// No description provided for @planner_setup_desc.
  ///
  /// In en, this message translates to:
  /// **'Quick setup before your plan'**
  String get planner_setup_desc;

  /// No description provided for @planner_ai_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'This plan is AI-generated for general guidance only.'**
  String get planner_ai_disclaimer;

  /// No description provided for @planner_restriction_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get planner_restriction_none;

  /// No description provided for @planner_restriction_vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get planner_restriction_vegetarian;

  /// No description provided for @planner_restriction_vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get planner_restriction_vegan;

  /// No description provided for @planner_restriction_gluten_free.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get planner_restriction_gluten_free;

  /// No description provided for @planner_restriction_keto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get planner_restriction_keto;

  /// No description provided for @planner_restriction_halal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get planner_restriction_halal;

  /// No description provided for @planner_cuisine_international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get planner_cuisine_international;

  /// No description provided for @planner_cuisine_south_asian.
  ///
  /// In en, this message translates to:
  /// **'South Asian'**
  String get planner_cuisine_south_asian;

  /// No description provided for @planner_cuisine_mediterranean.
  ///
  /// In en, this message translates to:
  /// **'Mediterranean'**
  String get planner_cuisine_mediterranean;

  /// No description provided for @planner_cuisine_east_asian.
  ///
  /// In en, this message translates to:
  /// **'East Asian'**
  String get planner_cuisine_east_asian;

  /// No description provided for @planner_cuisine_american.
  ///
  /// In en, this message translates to:
  /// **'American'**
  String get planner_cuisine_american;

  /// No description provided for @planner_cuisine_middle_eastern.
  ///
  /// In en, this message translates to:
  /// **'Middle Eastern'**
  String get planner_cuisine_middle_eastern;

  /// No description provided for @snap_offline_error.
  ///
  /// In en, this message translates to:
  /// **'AI analysis requires internet connection.'**
  String get snap_offline_error;

  /// No description provided for @home_metric_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get home_metric_goal;

  /// No description provided for @home_metric_meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get home_metric_meals;

  /// No description provided for @home_metric_goal_hint.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get home_metric_goal_hint;

  /// No description provided for @home_metric_meals_hint.
  ///
  /// In en, this message translates to:
  /// **'Logged today'**
  String get home_metric_meals_hint;

  /// No description provided for @home_no_meals_title.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet'**
  String get home_no_meals_title;

  /// No description provided for @home_no_meals_body.
  ///
  /// In en, this message translates to:
  /// **'Start with one quick snap.'**
  String get home_no_meals_body;

  /// No description provided for @home_first_meal_cta_title.
  ///
  /// In en, this message translates to:
  /// **'Scan a meal to start today'**
  String get home_first_meal_cta_title;

  /// No description provided for @home_first_meal_cta_body.
  ///
  /// In en, this message translates to:
  /// **'Use the camera to log calories and macros automatically.'**
  String get home_first_meal_cta_body;

  /// No description provided for @home_section_macros_today.
  ///
  /// In en, this message translates to:
  /// **'Macros today'**
  String get home_section_macros_today;

  /// No description provided for @home_eaten_progress.
  ///
  /// In en, this message translates to:
  /// **'EATEN'**
  String get home_eaten_progress;

  /// No description provided for @home_steps_today.
  ///
  /// In en, this message translates to:
  /// **'steps today'**
  String get home_steps_today;

  /// No description provided for @home_default_name.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get home_default_name;

  /// No description provided for @log_portion_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 bowl, 200g, 1 slice'**
  String get log_portion_hint;

  /// No description provided for @log_unknown_food.
  ///
  /// In en, this message translates to:
  /// **'Unknown Food'**
  String get log_unknown_food;

  /// No description provided for @home_goal_reached.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get home_goal_reached;

  /// No description provided for @home_completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get home_completed;

  /// No description provided for @home_kcal_left.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get home_kcal_left;

  /// No description provided for @assistant_typing.
  ///
  /// In en, this message translates to:
  /// **'Coach is typing...'**
  String get assistant_typing;

  /// No description provided for @assistant_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get assistant_retry;

  /// No description provided for @assistant_speech_not_available.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available on this device'**
  String get assistant_speech_not_available;

  /// No description provided for @paywall_pro_plan.
  ///
  /// In en, this message translates to:
  /// **'PRO PLAN'**
  String get paywall_pro_plan;

  /// No description provided for @paywall_unlock_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlock Unlimited'**
  String get paywall_unlock_unlimited;

  /// No description provided for @paywall_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Experience the full power of AI nutrition coaching.'**
  String get paywall_subtitle;

  /// No description provided for @paywall_feature_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get paywall_feature_unlimited;

  /// No description provided for @paywall_feature_scans.
  ///
  /// In en, this message translates to:
  /// **'Daily Scans'**
  String get paywall_feature_scans;

  /// No description provided for @paywall_feature_smart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get paywall_feature_smart;

  /// No description provided for @paywall_feature_plans.
  ///
  /// In en, this message translates to:
  /// **'Meal Plans'**
  String get paywall_feature_plans;

  /// No description provided for @paywall_feature_coach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get paywall_feature_coach;

  /// No description provided for @paywall_feature_advice.
  ///
  /// In en, this message translates to:
  /// **'Proactive Advice'**
  String get paywall_feature_advice;

  /// No description provided for @paywall_feature_ads.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free'**
  String get paywall_feature_ads;

  /// No description provided for @paywall_feature_no_ads.
  ///
  /// In en, this message translates to:
  /// **'Zero Interrupts'**
  String get paywall_feature_no_ads;

  /// No description provided for @paywall_best_value.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get paywall_best_value;

  /// No description provided for @paywall_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywall_restore;

  /// No description provided for @paywall_purchase_failed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get paywall_purchase_failed;

  /// No description provided for @paywall_save_percent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String paywall_save_percent(Object percent);

  /// No description provided for @paywall_trial_title.
  ///
  /// In en, this message translates to:
  /// **'How your trial works'**
  String get paywall_trial_title;

  /// No description provided for @paywall_trial_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get paywall_trial_today;

  /// No description provided for @paywall_trial_today_desc.
  ///
  /// In en, this message translates to:
  /// **'You get full access to all Pro features.'**
  String get paywall_trial_today_desc;

  /// No description provided for @paywall_trial_reminder.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String paywall_trial_reminder(Object day);

  /// No description provided for @paywall_trial_reminder_desc.
  ///
  /// In en, this message translates to:
  /// **'We send you a reminder that your trial is ending.'**
  String get paywall_trial_reminder_desc;

  /// No description provided for @paywall_trial_end.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String paywall_trial_end(Object day);

  /// No description provided for @paywall_trial_end_desc.
  ///
  /// In en, this message translates to:
  /// **'You are charged. Cancel anytime before this to avoid charges.'**
  String get paywall_trial_end_desc;

  /// No description provided for @paywall_referral_title.
  ///
  /// In en, this message translates to:
  /// **'Want it for free?'**
  String get paywall_referral_title;

  /// No description provided for @paywall_referral_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to get bonus scans.'**
  String get paywall_referral_subtitle;

  /// No description provided for @paywall_then.
  ///
  /// In en, this message translates to:
  /// **'Then {price}'**
  String paywall_then(Object price);

  /// No description provided for @settings_select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settings_select_language;

  /// No description provided for @settings_language_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the interface'**
  String get settings_language_desc;

  /// No description provided for @settings_lang_en_desc.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get settings_lang_en_desc;

  /// No description provided for @settings_lang_ar_desc.
  ///
  /// In en, this message translates to:
  /// **'Arabic (RTL Support)'**
  String get settings_lang_ar_desc;

  /// No description provided for @settings_lang_es_desc.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settings_lang_es_desc;

  /// No description provided for @settings_lang_fr_desc.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settings_lang_fr_desc;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'App Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_theme_system;

  /// No description provided for @settings_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// No description provided for @settings_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// No description provided for @settings_data_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Data & Sync'**
  String get settings_data_sync_title;

  /// No description provided for @settings_export_data.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settings_export_data;

  /// No description provided for @settings_export_desc.
  ///
  /// In en, this message translates to:
  /// **'Download your meals & metrics'**
  String get settings_export_desc;

  /// No description provided for @settings_cloud_sync_desc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to back up your data'**
  String get settings_cloud_sync_desc;

  /// No description provided for @settings_about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about_title;

  /// No description provided for @settings_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settings_privacy;

  /// No description provided for @settings_privacy_desc.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get settings_privacy_desc;

  /// No description provided for @settings_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settings_terms;

  /// No description provided for @settings_terms_desc.
  ///
  /// In en, this message translates to:
  /// **'Usage terms & conditions'**
  String get settings_terms_desc;

  /// No description provided for @settings_about_snapcal.
  ///
  /// In en, this message translates to:
  /// **'About SnapCal'**
  String get settings_about_snapcal;

  /// No description provided for @settings_upgrade_pro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get settings_upgrade_pro;

  /// No description provided for @settings_upgrade_desc.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited scans & AI coach'**
  String get settings_upgrade_desc;

  /// No description provided for @planner_free_limit_body.
  ///
  /// In en, this message translates to:
  /// **'Free users can view Mon & Tue only.'**
  String get planner_free_limit_body;

  /// No description provided for @planner_grocery_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Generate a weekly plan first and your grocery list will appear here.'**
  String get planner_grocery_empty_body;

  /// No description provided for @planner_grocery_pro_body.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to view and manage your weekly grocery list.'**
  String get planner_grocery_pro_body;

  /// No description provided for @planner_regenerate_body.
  ///
  /// In en, this message translates to:
  /// **'This will replace {day}\'s meals with fresh options.'**
  String planner_regenerate_body(String day);

  /// No description provided for @planner_setup_body.
  ///
  /// In en, this message translates to:
  /// **'Tell us your goals and we\'ll build a custom 7-day meal plan for you.'**
  String get planner_setup_body;

  /// No description provided for @planner_no_meals_body.
  ///
  /// In en, this message translates to:
  /// **'Try regenerating this day.'**
  String get planner_no_meals_body;

  /// No description provided for @report_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get report_weekly;

  /// No description provided for @report_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get report_monthly;

  /// No description provided for @onboarding_step.
  ///
  /// In en, this message translates to:
  /// **'STEP {current} OF {total}'**
  String onboarding_step(int current, int total);

  /// No description provided for @onboarding_get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_get_started;

  /// No description provided for @onboarding_start_journey.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get onboarding_start_journey;

  /// No description provided for @onboarding_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_continue;

  /// No description provided for @onboarding_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Your goal.\nYour calories.\nYour pace.'**
  String get onboarding_welcome_title;

  /// No description provided for @onboarding_welcome_body.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions to set your personalized daily calorie target.'**
  String get onboarding_welcome_body;

  /// No description provided for @onboarding_basic_intro_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DETAILS'**
  String get onboarding_basic_intro_eyebrow;

  /// No description provided for @onboarding_basic_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Set your baseline metrics.'**
  String get onboarding_basic_intro_title;

  /// No description provided for @onboarding_basic_intro_body.
  ///
  /// In en, this message translates to:
  /// **'We use these to calculate your resting metabolic rate (RMR).'**
  String get onboarding_basic_intro_body;

  /// No description provided for @onboarding_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboarding_age;

  /// No description provided for @onboarding_age_suffix.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get onboarding_age_suffix;

  /// No description provided for @onboarding_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboarding_gender;

  /// No description provided for @onboarding_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboarding_male;

  /// No description provided for @onboarding_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboarding_female;

  /// No description provided for @onboarding_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get onboarding_height;

  /// No description provided for @onboarding_weight_intro_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STATUS'**
  String get onboarding_weight_intro_eyebrow;

  /// No description provided for @onboarding_weight_intro_title.
  ///
  /// In en, this message translates to:
  /// **'What do you weigh today?'**
  String get onboarding_weight_intro_title;

  /// No description provided for @onboarding_weight_intro_body.
  ///
  /// In en, this message translates to:
  /// **'This helps us understand your starting point.'**
  String get onboarding_weight_intro_body;

  /// No description provided for @onboarding_weight_footer.
  ///
  /// In en, this message translates to:
  /// **'No judgment. Every journey starts with an honest metric.'**
  String get onboarding_weight_footer;

  /// No description provided for @onboarding_target_intro_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'THE TARGET'**
  String get onboarding_target_intro_eyebrow;

  /// No description provided for @onboarding_target_intro_title.
  ///
  /// In en, this message translates to:
  /// **'What is your goal weight?'**
  String get onboarding_target_intro_title;

  /// No description provided for @onboarding_target_intro_body.
  ///
  /// In en, this message translates to:
  /// **'We will structure your calories to hit this target within your timeline.'**
  String get onboarding_target_intro_body;

  /// No description provided for @onboarding_target_maintain_title.
  ///
  /// In en, this message translates to:
  /// **'Maintain your weight'**
  String get onboarding_target_maintain_title;

  /// No description provided for @onboarding_target_maintain_body.
  ///
  /// In en, this message translates to:
  /// **'We will build a plan to keep your weight stable while hitting your macros.'**
  String get onboarding_target_maintain_body;

  /// No description provided for @onboarding_timeline.
  ///
  /// In en, this message translates to:
  /// **'Target Timeline'**
  String get onboarding_timeline;

  /// No description provided for @onboarding_months.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{Month} other{Months}}'**
  String onboarding_months(int count);

  /// No description provided for @onboarding_activity_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'LIFESTYLE'**
  String get onboarding_activity_eyebrow;

  /// No description provided for @onboarding_activity_title.
  ///
  /// In en, this message translates to:
  /// **'How active are you?'**
  String get onboarding_activity_title;

  /// No description provided for @onboarding_activity_body.
  ///
  /// In en, this message translates to:
  /// **'Be honest—this is the biggest factor in your calorie burn.'**
  String get onboarding_activity_body;

  /// No description provided for @onboarding_activity_sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get onboarding_activity_sedentary;

  /// No description provided for @onboarding_activity_sedentary_desc.
  ///
  /// In en, this message translates to:
  /// **'Office job, little exercise'**
  String get onboarding_activity_sedentary_desc;

  /// No description provided for @onboarding_activity_lightly.
  ///
  /// In en, this message translates to:
  /// **'Lightly Active'**
  String get onboarding_activity_lightly;

  /// No description provided for @onboarding_activity_lightly_desc.
  ///
  /// In en, this message translates to:
  /// **'1-3 days of exercise/week'**
  String get onboarding_activity_lightly_desc;

  /// No description provided for @onboarding_activity_moderately.
  ///
  /// In en, this message translates to:
  /// **'Moderately Active'**
  String get onboarding_activity_moderately;

  /// No description provided for @onboarding_activity_moderately_desc.
  ///
  /// In en, this message translates to:
  /// **'3-5 days of exercise/week'**
  String get onboarding_activity_moderately_desc;

  /// No description provided for @onboarding_activity_active.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get onboarding_activity_active;

  /// No description provided for @onboarding_activity_active_desc.
  ///
  /// In en, this message translates to:
  /// **'3-5 days/week'**
  String get onboarding_activity_active_desc;

  /// No description provided for @onboarding_result_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR PLAN'**
  String get onboarding_result_eyebrow;

  /// No description provided for @onboarding_result_title.
  ///
  /// In en, this message translates to:
  /// **'Your target is ready.'**
  String get onboarding_result_title;

  /// No description provided for @onboarding_result_kcal_day.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get onboarding_result_kcal_day;

  /// No description provided for @onboarding_result_reach_by.
  ///
  /// In en, this message translates to:
  /// **'You\'ll reach your goal by {date}'**
  String onboarding_result_reach_by(String date);

  /// No description provided for @onboarding_result_pace.
  ///
  /// In en, this message translates to:
  /// **'Pace: {pace} {unit} / week'**
  String onboarding_result_pace(String pace, String unit);

  /// No description provided for @onboarding_error_age.
  ///
  /// In en, this message translates to:
  /// **'Enter an age between 13 and 100.'**
  String get onboarding_error_age;

  /// No description provided for @onboarding_error_height.
  ///
  /// In en, this message translates to:
  /// **'Enter a realistic height so we can calculate accurately.'**
  String get onboarding_error_height;

  /// No description provided for @onboarding_error_weight.
  ///
  /// In en, this message translates to:
  /// **'Enter a realistic current weight.'**
  String get onboarding_error_weight;

  /// No description provided for @onboarding_error_goal_weight.
  ///
  /// In en, this message translates to:
  /// **'Enter a realistic goal weight.'**
  String get onboarding_error_goal_weight;

  /// No description provided for @onboarding_error_timeline.
  ///
  /// In en, this message translates to:
  /// **'Adjust your timeline so we can build a valid plan.'**
  String get onboarding_error_timeline;

  /// No description provided for @onboarding_error_generic.
  ///
  /// In en, this message translates to:
  /// **'We could not build your plan. Please try again.'**
  String get onboarding_error_generic;

  /// No description provided for @onboarding_result_loading_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'AI Result'**
  String get onboarding_result_loading_eyebrow;

  /// No description provided for @onboarding_result_loading_title.
  ///
  /// In en, this message translates to:
  /// **'Building your calorie target.'**
  String get onboarding_result_loading_title;

  /// No description provided for @onboarding_result_loading_body.
  ///
  /// In en, this message translates to:
  /// **'We are combining your baseline, activity, and goal pace into a plan that is ready to use.'**
  String get onboarding_result_loading_body;

  /// No description provided for @onboarding_result_calibrating.
  ///
  /// In en, this message translates to:
  /// **'Calibrating your daily target...'**
  String get onboarding_result_calibrating;

  /// No description provided for @onboarding_result_error_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'CALCULATION ERROR'**
  String get onboarding_result_error_eyebrow;

  /// No description provided for @onboarding_result_error_title.
  ///
  /// In en, this message translates to:
  /// **'We could not finish your plan.'**
  String get onboarding_result_error_title;

  /// No description provided for @onboarding_result_error_body.
  ///
  /// In en, this message translates to:
  /// **'Try the last step again or adjust your inputs.'**
  String get onboarding_result_error_body;

  /// No description provided for @onboarding_result_success_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'AI CALIBRATION COMPLETE'**
  String get onboarding_result_success_eyebrow;

  /// No description provided for @onboarding_result_success_title.
  ///
  /// In en, this message translates to:
  /// **'Daily target is ready.'**
  String get onboarding_result_success_title;

  /// No description provided for @onboarding_result_success_body.
  ///
  /// In en, this message translates to:
  /// **'This number is personalized for your body and target pace.'**
  String get onboarding_result_success_body;

  /// No description provided for @onboarding_result_minor_warning.
  ///
  /// In en, this message translates to:
  /// **'Minor detection. Please consult a professional before starting any calorie restriction.'**
  String get onboarding_result_minor_warning;

  /// No description provided for @onboarding_result_daily_calories.
  ///
  /// In en, this message translates to:
  /// **'DAILY CALORIES'**
  String get onboarding_result_daily_calories;

  /// No description provided for @onboarding_result_strategy.
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get onboarding_result_strategy;

  /// No description provided for @onboarding_result_recommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get onboarding_result_recommendation;

  /// No description provided for @onboarding_activity_desk_life.
  ///
  /// In en, this message translates to:
  /// **'Desk Life'**
  String get onboarding_activity_desk_life;

  /// No description provided for @onboarding_activity_desk_life_desc.
  ///
  /// In en, this message translates to:
  /// **'Little to no exercise'**
  String get onboarding_activity_desk_life_desc;

  /// No description provided for @onboarding_activity_light_mover.
  ///
  /// In en, this message translates to:
  /// **'Light Mover'**
  String get onboarding_activity_light_mover;

  /// No description provided for @onboarding_activity_light_mover_desc.
  ///
  /// In en, this message translates to:
  /// **'1-3 days/week'**
  String get onboarding_activity_light_mover_desc;

  /// No description provided for @onboarding_activity_active_title.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get onboarding_activity_active_title;

  /// No description provided for @onboarding_activity_athlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get onboarding_activity_athlete;

  /// No description provided for @onboarding_activity_athlete_desc.
  ///
  /// In en, this message translates to:
  /// **'6-7 days/week'**
  String get onboarding_activity_athlete_desc;

  /// No description provided for @onboarding_activity_footer.
  ///
  /// In en, this message translates to:
  /// **'Active is selected by default. Tap once and we will keep moving.'**
  String get onboarding_activity_footer;

  /// No description provided for @onboarding_feature_target.
  ///
  /// In en, this message translates to:
  /// **'Personal calorie target'**
  String get onboarding_feature_target;

  /// No description provided for @onboarding_feature_macros.
  ///
  /// In en, this message translates to:
  /// **'Macro split'**
  String get onboarding_feature_macros;

  /// No description provided for @onboarding_feature_insight.
  ///
  /// In en, this message translates to:
  /// **'AI insight'**
  String get onboarding_feature_insight;

  /// No description provided for @planner_meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get planner_meal;

  /// No description provided for @planner_ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get planner_ingredients;

  /// No description provided for @common_mins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get common_mins;

  /// No description provided for @planner_kcal_total.
  ///
  /// In en, this message translates to:
  /// **'/ {goal} kcal'**
  String planner_kcal_total(int goal);

  /// No description provided for @planner_kcal_over.
  ///
  /// In en, this message translates to:
  /// **'+{delta} over'**
  String planner_kcal_over(int delta);

  /// No description provided for @planner_kcal_under.
  ///
  /// In en, this message translates to:
  /// **'{delta} under'**
  String planner_kcal_under(int delta);

  /// No description provided for @planner_kcal_on_target.
  ///
  /// In en, this message translates to:
  /// **'On target'**
  String get planner_kcal_on_target;

  /// No description provided for @snap_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get snap_gallery;

  /// No description provided for @snap_barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get snap_barcode;

  /// No description provided for @snap_pro_unlimited.
  ///
  /// In en, this message translates to:
  /// **'∞ Pro'**
  String get snap_pro_unlimited;

  /// No description provided for @snap_bento_plate.
  ///
  /// In en, this message translates to:
  /// **'Bento Plate'**
  String get snap_bento_plate;

  /// No description provided for @snap_items_detected.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}} detected on your plate.'**
  String snap_items_detected(num count);

  /// No description provided for @snap_total_meal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL MEAL'**
  String get snap_total_meal;

  /// No description provided for @snap_items_selected.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}} selected'**
  String snap_items_selected(num count);

  /// No description provided for @settings_body_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Body Profile'**
  String get settings_body_profile_title;

  /// No description provided for @settings_body_profile_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage your physical metrics and goals.'**
  String get settings_body_profile_desc;

  /// No description provided for @settings_display_name_label.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get settings_display_name_label;

  /// No description provided for @settings_set_name.
  ///
  /// In en, this message translates to:
  /// **'Set name'**
  String get settings_set_name;

  /// No description provided for @settings_current_weight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get settings_current_weight;

  /// No description provided for @settings_set_weight.
  ///
  /// In en, this message translates to:
  /// **'Set weight'**
  String get settings_set_weight;

  /// No description provided for @settings_height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settings_height;

  /// No description provided for @settings_set_height.
  ///
  /// In en, this message translates to:
  /// **'Set height'**
  String get settings_set_height;

  /// No description provided for @settings_target_weight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get settings_target_weight;

  /// No description provided for @settings_set_target.
  ///
  /// In en, this message translates to:
  /// **'Set target'**
  String get settings_set_target;

  /// No description provided for @settings_nutrition_goals_title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Goals'**
  String get settings_nutrition_goals_title;

  /// No description provided for @settings_daily_calories.
  ///
  /// In en, this message translates to:
  /// **'Daily calories'**
  String get settings_daily_calories;

  /// No description provided for @settings_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get settings_protein;

  /// No description provided for @settings_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get settings_carbs;

  /// No description provided for @settings_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get settings_fat;

  /// No description provided for @settings_optimize_btn.
  ///
  /// In en, this message translates to:
  /// **'Optimize My Nutrition Plan'**
  String get settings_optimize_btn;

  /// No description provided for @settings_optimizing.
  ///
  /// In en, this message translates to:
  /// **'Optimizing Plan...'**
  String get settings_optimizing;

  /// No description provided for @settings_recalculate_query.
  ///
  /// In en, this message translates to:
  /// **'I just optimized my nutrition plan. Please explain why these specific calories and macros were chosen for me based on my profile.'**
  String get settings_recalculate_query;

  /// No description provided for @settings_guest_account.
  ///
  /// In en, this message translates to:
  /// **'Guest Account'**
  String get settings_guest_account;

  /// No description provided for @settings_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get settings_sign_in;

  /// No description provided for @settings_member.
  ///
  /// In en, this message translates to:
  /// **'SnapCal Member'**
  String get settings_member;

  /// No description provided for @settings_auth_cta.
  ///
  /// In en, this message translates to:
  /// **'Sign up or Sign in'**
  String get settings_auth_cta;

  /// No description provided for @settings_preferences_title.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settings_preferences_title;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_meal_reminders.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get settings_meal_reminders;

  /// No description provided for @settings_daily_motivation.
  ///
  /// In en, this message translates to:
  /// **'Daily motivation'**
  String get settings_daily_motivation;

  /// No description provided for @settings_food_reminders.
  ///
  /// In en, this message translates to:
  /// **'Food scan reminders'**
  String get settings_food_reminders;

  /// No description provided for @settings_food_reminders_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to scan your meals'**
  String get settings_food_reminders_subtitle;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_account_title.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settings_account_title;

  /// No description provided for @settings_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settings_subscription;

  /// No description provided for @settings_pro_active.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get settings_pro_active;

  /// No description provided for @settings_manage_plan.
  ///
  /// In en, this message translates to:
  /// **'Manage plan'**
  String get settings_manage_plan;

  /// No description provided for @settings_create_account.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get settings_create_account;

  /// No description provided for @settings_sign_out_desc.
  ///
  /// In en, this message translates to:
  /// **'Leave this device session'**
  String get settings_sign_out_desc;

  /// No description provided for @settings_sync_data_desc.
  ///
  /// In en, this message translates to:
  /// **'Sync your data'**
  String get settings_sync_data_desc;

  /// No description provided for @settings_about_app.
  ///
  /// In en, this message translates to:
  /// **'About SnapCal'**
  String get settings_about_app;

  /// No description provided for @settings_legalese.
  ///
  /// In en, this message translates to:
  /// **'© 2026 SnapCal. All rights reserved.'**
  String get settings_legalese;

  /// No description provided for @onboarding_result_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain Current Weight'**
  String get onboarding_result_maintain;

  /// No description provided for @onboarding_result_weekly_rate.
  ///
  /// In en, this message translates to:
  /// **'~{rate} kg / week'**
  String onboarding_result_weekly_rate(String rate);

  /// No description provided for @error_connection_title.
  ///
  /// In en, this message translates to:
  /// **'Connection Issue'**
  String get error_connection_title;

  /// No description provided for @error_connection_body.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize SnapCal. Please check your data or Wi-Fi.'**
  String get error_connection_body;

  /// No description provided for @error_unexpected_title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error_unexpected_title;

  /// No description provided for @error_unexpected_body.
  ///
  /// In en, this message translates to:
  /// **'We encountered an unexpected error. Our team has been notified and we are working to fix it.'**
  String get error_unexpected_body;

  /// No description provided for @report_guest_user.
  ///
  /// In en, this message translates to:
  /// **'Valued User'**
  String get report_guest_user;

  /// No description provided for @report_avg_calories.
  ///
  /// In en, this message translates to:
  /// **'Avg. Calories'**
  String get report_avg_calories;

  /// No description provided for @report_consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get report_consistency;

  /// No description provided for @report_calorie_trend.
  ///
  /// In en, this message translates to:
  /// **'Calorie trend'**
  String get report_calorie_trend;

  /// No description provided for @report_macro_dist.
  ///
  /// In en, this message translates to:
  /// **'Macro distribution'**
  String get report_macro_dist;

  /// No description provided for @report_macro_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get report_macro_protein;

  /// No description provided for @report_macro_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get report_macro_carbs;

  /// No description provided for @report_macro_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get report_macro_fat;

  /// No description provided for @report_no_weight_title.
  ///
  /// In en, this message translates to:
  /// **'No weight entries yet'**
  String get report_no_weight_title;

  /// No description provided for @report_no_weight_body.
  ///
  /// In en, this message translates to:
  /// **'Add your first entry so your body trend can start.'**
  String get report_no_weight_body;

  /// No description provided for @report_log_weight.
  ///
  /// In en, this message translates to:
  /// **'Log weight'**
  String get report_log_weight;

  /// No description provided for @report_weight_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get report_weight_current;

  /// No description provided for @report_weight_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get report_weight_change;

  /// No description provided for @report_progress_timeline.
  ///
  /// In en, this message translates to:
  /// **'Progress Timeline'**
  String get report_progress_timeline;

  /// No description provided for @report_progress_gallery.
  ///
  /// In en, this message translates to:
  /// **'Visual body-transformation gallery'**
  String get report_progress_gallery;

  /// No description provided for @report_weight_analytics.
  ///
  /// In en, this message translates to:
  /// **'Weight analytics'**
  String get report_weight_analytics;

  /// No description provided for @report_recent_history.
  ///
  /// In en, this message translates to:
  /// **'Recent history'**
  String get report_recent_history;

  /// No description provided for @report_body_fat_pct.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Fat'**
  String report_body_fat_pct(String percent);

  /// No description provided for @weight_hint.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight_hint;

  /// No description provided for @body_fat_hint.
  ///
  /// In en, this message translates to:
  /// **'Body fat (optional)'**
  String get body_fat_hint;

  /// No description provided for @snap_scan_barcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get snap_scan_barcode;

  /// No description provided for @snap_barcode_hint.
  ///
  /// In en, this message translates to:
  /// **'Place the barcode inside the frame.'**
  String get snap_barcode_hint;

  /// No description provided for @snap_torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get snap_torch;

  /// No description provided for @snap_flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get snap_flip;

  /// No description provided for @settings_health_sync.
  ///
  /// In en, this message translates to:
  /// **'Health Sync'**
  String get settings_health_sync;

  /// No description provided for @settings_health_sync_sub.
  ///
  /// In en, this message translates to:
  /// **'Sync steps and calories burned'**
  String get settings_health_sync_sub;

  /// No description provided for @home_metric_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get home_metric_activity;

  /// No description provided for @home_metric_activity_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get home_metric_activity_sync;

  /// No description provided for @home_metric_activity_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable Health'**
  String get home_metric_activity_enable;

  /// No description provided for @progress_generate_video.
  ///
  /// In en, this message translates to:
  /// **'Generate Journey Video'**
  String get progress_generate_video;

  /// No description provided for @progress_video_failed.
  ///
  /// In en, this message translates to:
  /// **'Video generation failed. Try again.'**
  String get progress_video_failed;

  /// No description provided for @progress_video_min_photos.
  ///
  /// In en, this message translates to:
  /// **'Take at least 2 progress photos first!'**
  String get progress_video_min_photos;

  /// No description provided for @progress_video_share_text.
  ///
  /// In en, this message translates to:
  /// **'My SnapCal Transformation Journey! 🚀'**
  String get progress_video_share_text;

  /// No description provided for @widget_status_on_track.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get widget_status_on_track;

  /// No description provided for @widget_status_over_goal.
  ///
  /// In en, this message translates to:
  /// **'Over Goal'**
  String get widget_status_over_goal;

  /// No description provided for @widget_status_almost_there.
  ///
  /// In en, this message translates to:
  /// **'Almost There'**
  String get widget_status_almost_there;

  /// No description provided for @feature_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Wrap'**
  String get feature_insights_title;

  /// No description provided for @feature_insights_desc.
  ///
  /// In en, this message translates to:
  /// **'Your week in review'**
  String get feature_insights_desc;

  /// No description provided for @feature_insights_avg_cal.
  ///
  /// In en, this message translates to:
  /// **'Avg {cal} kcal/day'**
  String feature_insights_avg_cal(String cal);

  /// No description provided for @feature_insights_on_track.
  ///
  /// In en, this message translates to:
  /// **'{days} Days on Track'**
  String feature_insights_on_track(String days);

  /// No description provided for @feature_insights_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating Insights...'**
  String get feature_insights_generating;

  /// No description provided for @feature_insights_share.
  ///
  /// In en, this message translates to:
  /// **'Share My Week'**
  String get feature_insights_share;

  /// No description provided for @feature_templates_title.
  ///
  /// In en, this message translates to:
  /// **'My Routines'**
  String get feature_templates_title;

  /// No description provided for @feature_templates_empty.
  ///
  /// In en, this message translates to:
  /// **'Save your first routine! Log a combo, then tap \'Save as Routine\'.'**
  String get feature_templates_empty;

  /// No description provided for @feature_templates_save_prompt.
  ///
  /// In en, this message translates to:
  /// **'Save as Routine?'**
  String get feature_templates_save_prompt;

  /// No description provided for @feature_templates_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Morning Fuel'**
  String get feature_templates_name_hint;

  /// No description provided for @feature_templates_save_btn.
  ///
  /// In en, this message translates to:
  /// **'Save Routine'**
  String get feature_templates_save_btn;

  /// No description provided for @feature_templates_update_btn.
  ///
  /// In en, this message translates to:
  /// **'Update Routine'**
  String get feature_templates_update_btn;

  /// No description provided for @feature_templates_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Free limit reached. Upgrade to Pro for unlimited routines!'**
  String get feature_templates_limit_reached;

  /// No description provided for @feature_templates_logged.
  ///
  /// In en, this message translates to:
  /// **'Routine logged successfully!'**
  String get feature_templates_logged;

  /// No description provided for @feature_achievements_title.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get feature_achievements_title;

  /// No description provided for @feature_achievements_unlocked.
  ///
  /// In en, this message translates to:
  /// **'{count} Unlocked'**
  String feature_achievements_unlocked(String count);

  /// No description provided for @achievement_first_flame.
  ///
  /// In en, this message translates to:
  /// **'First Flame'**
  String get achievement_first_flame;

  /// No description provided for @achievement_first_flame_desc.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal'**
  String get achievement_first_flame_desc;

  /// No description provided for @achievement_consistency_king.
  ///
  /// In en, this message translates to:
  /// **'Consistency King'**
  String get achievement_consistency_king;

  /// No description provided for @achievement_consistency_king_desc.
  ///
  /// In en, this message translates to:
  /// **'7-day logging streak'**
  String get achievement_consistency_king_desc;

  /// No description provided for @achievement_iron_will.
  ///
  /// In en, this message translates to:
  /// **'Iron Will'**
  String get achievement_iron_will;

  /// No description provided for @achievement_iron_will_desc.
  ///
  /// In en, this message translates to:
  /// **'30-day logging streak'**
  String get achievement_iron_will_desc;

  /// No description provided for @achievement_unstoppable.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable'**
  String get achievement_unstoppable;

  /// No description provided for @achievement_unstoppable_desc.
  ///
  /// In en, this message translates to:
  /// **'100-day logging streak'**
  String get achievement_unstoppable_desc;

  /// No description provided for @achievement_bullseye.
  ///
  /// In en, this message translates to:
  /// **'Bullseye'**
  String get achievement_bullseye;

  /// No description provided for @achievement_bullseye_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit calorie goal exactly'**
  String get achievement_bullseye_desc;

  /// No description provided for @achievement_precision_pro.
  ///
  /// In en, this message translates to:
  /// **'Precision Pro'**
  String get achievement_precision_pro;

  /// No description provided for @achievement_precision_pro_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit calorie goal 7 days straight'**
  String get achievement_precision_pro_desc;

  /// No description provided for @achievement_macro_master.
  ///
  /// In en, this message translates to:
  /// **'Macro Master'**
  String get achievement_macro_master;

  /// No description provided for @achievement_macro_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit all macros in one day'**
  String get achievement_macro_master_desc;

  /// No description provided for @achievement_perfect_week.
  ///
  /// In en, this message translates to:
  /// **'Perfect Week'**
  String get achievement_perfect_week;

  /// No description provided for @achievement_perfect_week_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit all goals for 7 days'**
  String get achievement_perfect_week_desc;

  /// No description provided for @achievement_first_sip.
  ///
  /// In en, this message translates to:
  /// **'First Sip'**
  String get achievement_first_sip;

  /// No description provided for @achievement_first_sip_desc.
  ///
  /// In en, this message translates to:
  /// **'Log water for the first time'**
  String get achievement_first_sip_desc;

  /// No description provided for @achievement_hydration_hero.
  ///
  /// In en, this message translates to:
  /// **'Hydration Hero'**
  String get achievement_hydration_hero;

  /// No description provided for @achievement_hydration_hero_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit water goal 30 days'**
  String get achievement_hydration_hero_desc;

  /// No description provided for @achievement_ocean_mode.
  ///
  /// In en, this message translates to:
  /// **'Ocean Mode'**
  String get achievement_ocean_mode;

  /// No description provided for @achievement_ocean_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Hit water goal 100 days'**
  String get achievement_ocean_mode_desc;

  /// No description provided for @achievement_first_snap.
  ///
  /// In en, this message translates to:
  /// **'First Snap'**
  String get achievement_first_snap;

  /// No description provided for @achievement_first_snap_desc.
  ///
  /// In en, this message translates to:
  /// **'Log 1 meal via camera'**
  String get achievement_first_snap_desc;

  /// No description provided for @achievement_snap_master.
  ///
  /// In en, this message translates to:
  /// **'Snap Master'**
  String get achievement_snap_master;

  /// No description provided for @achievement_snap_master_desc.
  ///
  /// In en, this message translates to:
  /// **'Log 100 meals'**
  String get achievement_snap_master_desc;

  /// No description provided for @achievement_snap_legend.
  ///
  /// In en, this message translates to:
  /// **'Snap Legend'**
  String get achievement_snap_legend;

  /// No description provided for @achievement_snap_legend_desc.
  ///
  /// In en, this message translates to:
  /// **'Log 500 meals'**
  String get achievement_snap_legend_desc;

  /// No description provided for @achievement_first_checkin.
  ///
  /// In en, this message translates to:
  /// **'First Check-In'**
  String get achievement_first_checkin;

  /// No description provided for @achievement_first_checkin_desc.
  ///
  /// In en, this message translates to:
  /// **'Log first body photo'**
  String get achievement_first_checkin_desc;

  /// No description provided for @achievement_transformation.
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get achievement_transformation;

  /// No description provided for @achievement_transformation_desc.
  ///
  /// In en, this message translates to:
  /// **'Log 10 body photos'**
  String get achievement_transformation_desc;

  /// No description provided for @achievement_journey_video.
  ///
  /// In en, this message translates to:
  /// **'Journey Video'**
  String get achievement_journey_video;

  /// No description provided for @achievement_journey_video_desc.
  ///
  /// In en, this message translates to:
  /// **'Generate transformation video'**
  String get achievement_journey_video_desc;

  /// No description provided for @feature_achievements_unlocked_title.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get feature_achievements_unlocked_title;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @feature_insights_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI-powered weekly nutrition summary is ready!'**
  String get feature_insights_subtitle;

  /// No description provided for @feature_insights_share_text.
  ///
  /// In en, this message translates to:
  /// **'Check out my weekly nutrition summary from SnapCal! 📊'**
  String get feature_insights_share_text;

  /// No description provided for @settings_guest_title.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Progress'**
  String get settings_guest_title;

  /// No description provided for @settings_guest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data securely.'**
  String get settings_guest_subtitle;

  /// No description provided for @activity_tracking_status.
  ///
  /// In en, this message translates to:
  /// **'TRACKING STATUS'**
  String get activity_tracking_status;

  /// No description provided for @activity_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activity_active;

  /// No description provided for @activity_description.
  ///
  /// In en, this message translates to:
  /// **'Your phone sensors are actively tracking your steps for today\'s calorie burn.'**
  String get activity_description;

  /// No description provided for @activity_authorize_desc.
  ///
  /// In en, this message translates to:
  /// **'To track your steps automatically, please authorize activity recognition.'**
  String get activity_authorize_desc;

  /// No description provided for @activity_authorize_btn.
  ///
  /// In en, this message translates to:
  /// **'Authorize Tracking'**
  String get activity_authorize_btn;

  /// No description provided for @activity_motivation_low.
  ///
  /// In en, this message translates to:
  /// **'Every step counts. Let\'s get moving today!'**
  String get activity_motivation_low;

  /// No description provided for @activity_motivation_mid.
  ///
  /// In en, this message translates to:
  /// **'You\'re on your way! A quick walk could help you reach your goal.'**
  String get activity_motivation_mid;

  /// No description provided for @activity_motivation_high.
  ///
  /// In en, this message translates to:
  /// **'Almost there! You\'re crushing your activity goals.'**
  String get activity_motivation_high;

  /// No description provided for @activity_motivation_elite.
  ///
  /// In en, this message translates to:
  /// **'Outstanding! You\'re in the elite active zone today.'**
  String get activity_motivation_elite;

  /// No description provided for @home_scan_food.
  ///
  /// In en, this message translates to:
  /// **'Scan food'**
  String get home_scan_food;

  /// No description provided for @home_go_pro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get home_go_pro;

  /// No description provided for @home_pro_badge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get home_pro_badge;

  /// No description provided for @settings_upgrade_to_pro.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE TO PRO'**
  String get settings_upgrade_to_pro;

  /// No description provided for @settings_emerald_badge.
  ///
  /// In en, this message translates to:
  /// **'EMERALD'**
  String get settings_emerald_badge;

  /// No description provided for @coach_limit_title.
  ///
  /// In en, this message translates to:
  /// **'DAILY LIMIT REACHED'**
  String get coach_limit_title;

  /// No description provided for @coach_limit_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium for unlimited coaching and smarter meal guidance tailored to your goals.'**
  String get coach_limit_subtitle;

  /// No description provided for @coach_limit_btn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for Unlimited Chat'**
  String get coach_limit_btn;

  /// No description provided for @coach_see_options.
  ///
  /// In en, this message translates to:
  /// **'See Subscription Options'**
  String get coach_see_options;

  /// No description provided for @coach_locked_title.
  ///
  /// In en, this message translates to:
  /// **'Know what to eat next.'**
  String get coach_locked_title;

  /// No description provided for @coach_locked_desc.
  ///
  /// In en, this message translates to:
  /// **'AI Coach reads today\'s calories, macros, and goal, then gives clear food advice.'**
  String get coach_locked_desc;

  /// No description provided for @coach_preview_meal_title.
  ///
  /// In en, this message translates to:
  /// **'Next meal suggestion'**
  String get coach_preview_meal_title;

  /// No description provided for @coach_preview_meal_body.
  ///
  /// In en, this message translates to:
  /// **'Best next meal: grilled chicken rice bowl, around 550 kcal.'**
  String get coach_preview_meal_body;

  /// No description provided for @coach_preview_macro_title.
  ///
  /// In en, this message translates to:
  /// **'Macro correction'**
  String get coach_preview_macro_title;

  /// No description provided for @coach_preview_macro_body.
  ///
  /// In en, this message translates to:
  /// **'You still need 45g protein and 120g carbs today.'**
  String get coach_preview_macro_body;

  /// No description provided for @coach_preview_feedback_title.
  ///
  /// In en, this message translates to:
  /// **'Daily progress feedback'**
  String get coach_preview_feedback_title;

  /// No description provided for @coach_preview_feedback_body.
  ///
  /// In en, this message translates to:
  /// **'You are low on protein. Add eggs, tuna, or Greek yogurt next.'**
  String get coach_preview_feedback_body;

  /// No description provided for @report_prompt_title.
  ///
  /// In en, this message translates to:
  /// **'YOUR WEEKLY REPORT IS READY'**
  String get report_prompt_title;

  /// No description provided for @report_prompt_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock a deeper look at why some days went over target and how to improve next week.'**
  String get report_prompt_subtitle;

  /// No description provided for @report_prompt_btn.
  ///
  /// In en, this message translates to:
  /// **'Unlock Weekly Report'**
  String get report_prompt_btn;

  /// No description provided for @scan_overlay_scanning.
  ///
  /// In en, this message translates to:
  /// **'AI VISION SCANNING'**
  String get scan_overlay_scanning;

  /// No description provided for @scan_overlay_desc.
  ///
  /// In en, this message translates to:
  /// **'Detecting ingredients and calculating\nnutritional density with Gemini...'**
  String get scan_overlay_desc;

  /// No description provided for @scan_overlay_manual.
  ///
  /// In en, this message translates to:
  /// **'LOG MANUALLY'**
  String get scan_overlay_manual;

  /// No description provided for @report_card_title.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY PROGRESS REPORT'**
  String get report_card_title;

  /// No description provided for @report_card_subtitle.
  ///
  /// In en, this message translates to:
  /// **'See why some days went over target and get personalized suggestions to fix it.'**
  String get report_card_subtitle;

  /// No description provided for @startup_launch_issue.
  ///
  /// In en, this message translates to:
  /// **'Launch Encountered an Issue'**
  String get startup_launch_issue;

  /// No description provided for @startup_initialization_slow.
  ///
  /// In en, this message translates to:
  /// **'Initialization is taking longer than expected.'**
  String get startup_initialization_slow;

  /// No description provided for @startup_setup_failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while setting up the app. Please try again.'**
  String get startup_setup_failed;

  /// No description provided for @startup_retry_launch.
  ///
  /// In en, this message translates to:
  /// **'Retry Launch'**
  String get startup_retry_launch;

  /// No description provided for @startup_initialization_error.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get startup_initialization_error;

  /// No description provided for @startup_error_body.
  ///
  /// In en, this message translates to:
  /// **'The application encountered a startup error. Please try restarting.'**
  String get startup_error_body;

  /// No description provided for @startup_reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get startup_reload;

  /// No description provided for @activity_live_tracking.
  ///
  /// In en, this message translates to:
  /// **'LIVE TRACKING'**
  String get activity_live_tracking;

  /// No description provided for @activity_stationary.
  ///
  /// In en, this message translates to:
  /// **'STATIONARY'**
  String get activity_stationary;

  /// No description provided for @activity_steps_today_label.
  ///
  /// In en, this message translates to:
  /// **'STEPS TODAY'**
  String get activity_steps_today_label;

  /// No description provided for @activity_calories_label.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get activity_calories_label;

  /// No description provided for @activity_goal_label.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get activity_goal_label;

  /// No description provided for @activity_tracking_engine.
  ///
  /// In en, this message translates to:
  /// **'TRACKING ENGINE'**
  String get activity_tracking_engine;

  /// No description provided for @activity_active_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Active & Encrypted'**
  String get activity_active_encrypted;

  /// No description provided for @activity_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get activity_permission_required;

  /// No description provided for @activity_steps_synced.
  ///
  /// In en, this message translates to:
  /// **'Your steps are synced in real-time.'**
  String get activity_steps_synced;

  /// No description provided for @activity_enable_tracking.
  ///
  /// In en, this message translates to:
  /// **'Enable tracking to see your progress.'**
  String get activity_enable_tracking;

  /// No description provided for @feature_insights_share_error.
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String feature_insights_share_error(String error);

  /// No description provided for @feature_insights_empty.
  ///
  /// In en, this message translates to:
  /// **'No data for this week yet.'**
  String get feature_insights_empty;

  /// No description provided for @feature_insights_calorie_trend.
  ///
  /// In en, this message translates to:
  /// **'Calorie Trend'**
  String get feature_insights_calorie_trend;

  /// No description provided for @feature_insights_ai_coach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach Insights'**
  String get feature_insights_ai_coach;

  /// No description provided for @auth_intro_body.
  ///
  /// In en, this message translates to:
  /// **'Your journey to a healthier you starts here.'**
  String get auth_intro_body;

  /// No description provided for @auth_back_to_social.
  ///
  /// In en, this message translates to:
  /// **'Back to Social Login'**
  String get auth_back_to_social;

  /// No description provided for @auth_create_account.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_create_account;

  /// No description provided for @auth_welcome_back_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get auth_welcome_back_title;

  /// No description provided for @home_welcome_guest.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SnapCal'**
  String get home_welcome_guest;

  /// No description provided for @auth_lets_dive.
  ///
  /// In en, this message translates to:
  /// **'Let\'s dive in'**
  String get auth_lets_dive;

  /// No description provided for @auth_sign_up_short.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_sign_up_short;

  /// No description provided for @auth_log_in.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get auth_log_in;

  /// No description provided for @auth_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get auth_have_account;

  /// No description provided for @auth_no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get auth_no_account;

  /// No description provided for @common_or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get common_or;

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get common_yesterday;

  /// No description provided for @common_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get common_tomorrow;

  /// No description provided for @common_maybe_later.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get common_maybe_later;

  /// No description provided for @settings_category_body_profile_sub.
  ///
  /// In en, this message translates to:
  /// **'Body metrics, units, and target weight'**
  String get settings_category_body_profile_sub;

  /// No description provided for @settings_category_nutrition_sub.
  ///
  /// In en, this message translates to:
  /// **'Calories, protein, carbs, and fat targets'**
  String get settings_category_nutrition_sub;

  /// No description provided for @settings_category_preferences_sub.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, reminders, and meal planning'**
  String get settings_category_preferences_sub;

  /// No description provided for @settings_category_achievements_sub.
  ///
  /// In en, this message translates to:
  /// **'Streaks, milestones, and progress rewards'**
  String get settings_category_achievements_sub;

  /// No description provided for @settings_category_account_sub.
  ///
  /// In en, this message translates to:
  /// **'Sign in, profile name, and account controls'**
  String get settings_category_account_sub;

  /// No description provided for @settings_category_data_sync_sub.
  ///
  /// In en, this message translates to:
  /// **'Backup, restore, and local app data'**
  String get settings_category_data_sync_sub;

  /// No description provided for @settings_category_about_sub.
  ///
  /// In en, this message translates to:
  /// **'Version, privacy, terms, and app information'**
  String get settings_category_about_sub;

  /// No description provided for @home_go_deeper_title.
  ///
  /// In en, this message translates to:
  /// **'Go deeper'**
  String get home_go_deeper_title;

  /// No description provided for @home_go_deeper_body.
  ///
  /// In en, this message translates to:
  /// **'AI day reviews, macro trends, and full history.'**
  String get home_go_deeper_body;

  /// No description provided for @home_daily_wellness.
  ///
  /// In en, this message translates to:
  /// **'Daily Wellness'**
  String get home_daily_wellness;

  /// No description provided for @home_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get home_add;

  /// No description provided for @home_daily_score.
  ///
  /// In en, this message translates to:
  /// **'Daily score'**
  String get home_daily_score;

  /// No description provided for @log_monthly_calendar_soon.
  ///
  /// In en, this message translates to:
  /// **'Monthly calendar coming soon'**
  String get log_monthly_calendar_soon;

  /// No description provided for @log_today_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track what you eat today'**
  String get log_today_subtitle;

  /// No description provided for @log_review_day.
  ///
  /// In en, this message translates to:
  /// **'Review this day'**
  String get log_review_day;

  /// No description provided for @log_scan_food.
  ///
  /// In en, this message translates to:
  /// **'Scan Food'**
  String get log_scan_food;

  /// No description provided for @feature_templates_saved_meals.
  ///
  /// In en, this message translates to:
  /// **'SAVED MEALS'**
  String get feature_templates_saved_meals;

  /// No description provided for @feature_templates_saved_added.
  ///
  /// In en, this message translates to:
  /// **'Saved meal added'**
  String get feature_templates_saved_added;

  /// No description provided for @feature_templates_deleted.
  ///
  /// In en, this message translates to:
  /// **'Routine deleted'**
  String get feature_templates_deleted;

  /// No description provided for @premium_analysis_title.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM ANALYSIS'**
  String get premium_analysis_title;

  /// No description provided for @premium_analysis_body.
  ///
  /// In en, this message translates to:
  /// **'Get a better version of this meal based on your goal with AI suggestions.'**
  String get premium_analysis_body;

  /// No description provided for @result_meal_name.
  ///
  /// In en, this message translates to:
  /// **'Meal name'**
  String get result_meal_name;

  /// No description provided for @result_feast.
  ///
  /// In en, this message translates to:
  /// **'Feast'**
  String get result_feast;

  /// No description provided for @result_ai_meal_insight.
  ///
  /// In en, this message translates to:
  /// **'AI meal insight'**
  String get result_ai_meal_insight;

  /// No description provided for @result_ai_meal_body.
  ///
  /// In en, this message translates to:
  /// **'Balance this meal with one smart suggestion.'**
  String get result_ai_meal_body;

  /// No description provided for @result_add_new_item.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW ITEM'**
  String get result_add_new_item;

  /// No description provided for @result_total_calories.
  ///
  /// In en, this message translates to:
  /// **'TOTAL CALORIES'**
  String get result_total_calories;

  /// No description provided for @result_food_details.
  ///
  /// In en, this message translates to:
  /// **'Food details'**
  String get result_food_details;

  /// No description provided for @result_food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get result_food;

  /// No description provided for @result_portion_label.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get result_portion_label;

  /// No description provided for @result_add_item.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get result_add_item;

  /// No description provided for @result_nutrition_details.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Details'**
  String get result_nutrition_details;

  /// No description provided for @result_unlock_nutrition.
  ///
  /// In en, this message translates to:
  /// **'Unlock nutrition details'**
  String get result_unlock_nutrition;

  /// No description provided for @result_add_to_log.
  ///
  /// In en, this message translates to:
  /// **'Add to Log'**
  String get result_add_to_log;

  /// No description provided for @paywall_cancel_anytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. No commitment.'**
  String get paywall_cancel_anytime;

  /// No description provided for @paywall_terms_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get paywall_terms_conditions;

  /// No description provided for @paywall_trial_7_day.
  ///
  /// In en, this message translates to:
  /// **'7-day trial'**
  String get paywall_trial_7_day;

  /// No description provided for @paywall_scan_limit_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You used 3/3 free scans today. Unlock unlimited AI food scans and instant calorie breakdowns.'**
  String get paywall_scan_limit_subtitle;

  /// No description provided for @paywall_coach_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited coaching, macro guidance, and meal suggestions tailored to your day.'**
  String get paywall_coach_subtitle;

  /// No description provided for @paywall_planner_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock full weekly plans, grocery lists, preferences, and AI meal regenerations.'**
  String get paywall_planner_subtitle;

  /// No description provided for @paywall_reports_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock deeper analysis, weekly trends, and practical AI suggestions after every {feature}.'**
  String paywall_reports_subtitle(String feature);

  /// No description provided for @paywall_progress_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock more progress photos, comparisons, and transformation tracking beyond the monthly free limit.'**
  String get paywall_progress_subtitle;

  /// No description provided for @paywall_ad_removal_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Go Pro to remove ads and unlock the full AI nutrition experience.'**
  String get paywall_ad_removal_subtitle;

  /// No description provided for @progress_weight_trend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend'**
  String get progress_weight_trend;

  /// No description provided for @progress_log_custom_weight.
  ///
  /// In en, this message translates to:
  /// **'Tap to log your customized weight'**
  String get progress_log_custom_weight;

  /// No description provided for @log_calories_eaten.
  ///
  /// In en, this message translates to:
  /// **'Calories eaten'**
  String get log_calories_eaten;

  /// No description provided for @log_kcal_over.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String log_kcal_over(int amount);

  /// No description provided for @log_kcal_left.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String log_kcal_left(int amount);

  /// No description provided for @log_no_details.
  ///
  /// In en, this message translates to:
  /// **'No details logged for this day yet.'**
  String get log_no_details;

  /// No description provided for @log_over_target_insight.
  ///
  /// In en, this message translates to:
  /// **'You logged {amount} kcal over target. Review the heavier meals below.'**
  String log_over_target_insight(int amount);

  /// No description provided for @log_low_protein_insight.
  ///
  /// In en, this message translates to:
  /// **'You logged {calories} kcal and protein was behind target.'**
  String log_low_protein_insight(int calories);

  /// No description provided for @log_water_behind_insight.
  ///
  /// In en, this message translates to:
  /// **'You logged {calories} kcal. Water is still behind today.'**
  String log_water_behind_insight(int calories);

  /// No description provided for @log_balanced_day_insight.
  ///
  /// In en, this message translates to:
  /// **'You logged {calories} kcal with a balanced day so far.'**
  String log_balanced_day_insight(int calories);

  /// No description provided for @feature_templates_save_desc.
  ///
  /// In en, this message translates to:
  /// **'Save these {count} items for one-tap logging later.'**
  String feature_templates_save_desc(int count);

  /// No description provided for @achievement_category_consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get achievement_category_consistency;

  /// No description provided for @achievement_category_precision.
  ///
  /// In en, this message translates to:
  /// **'Precision'**
  String get achievement_category_precision;

  /// No description provided for @achievement_category_hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get achievement_category_hydration;

  /// No description provided for @achievement_category_logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get achievement_category_logging;

  /// No description provided for @achievement_category_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get achievement_category_progress;

  /// No description provided for @achievement_unlocked_label.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievement_unlocked_label;

  /// No description provided for @report_pdf_title.
  ///
  /// In en, this message translates to:
  /// **'AI NUTRITION REPORT'**
  String get report_pdf_title;

  /// No description provided for @report_pdf_user.
  ///
  /// In en, this message translates to:
  /// **'User: {name}'**
  String report_pdf_user(String name);

  /// No description provided for @report_pdf_weekly_performance.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY PERFORMANCE'**
  String get report_pdf_weekly_performance;

  /// No description provided for @report_pdf_total_protein.
  ///
  /// In en, this message translates to:
  /// **'Total Protein'**
  String get report_pdf_total_protein;

  /// No description provided for @report_pdf_active_streak.
  ///
  /// In en, this message translates to:
  /// **'Active Streak'**
  String get report_pdf_active_streak;

  /// No description provided for @report_pdf_grams.
  ///
  /// In en, this message translates to:
  /// **'grams'**
  String get report_pdf_grams;

  /// No description provided for @report_pdf_days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get report_pdf_days;

  /// No description provided for @report_pdf_macro_distribution.
  ///
  /// In en, this message translates to:
  /// **'MACRONUTRIENT DISTRIBUTION'**
  String get report_pdf_macro_distribution;

  /// No description provided for @report_pdf_nutrient.
  ///
  /// In en, this message translates to:
  /// **'Nutrient'**
  String get report_pdf_nutrient;

  /// No description provided for @report_pdf_total_consumed.
  ///
  /// In en, this message translates to:
  /// **'Total Consumed'**
  String get report_pdf_total_consumed;

  /// No description provided for @report_pdf_daily_target.
  ///
  /// In en, this message translates to:
  /// **'Daily Target'**
  String get report_pdf_daily_target;

  /// No description provided for @report_pdf_goal_status.
  ///
  /// In en, this message translates to:
  /// **'Goal Status'**
  String get report_pdf_goal_status;

  /// No description provided for @report_pdf_carbohydrates.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get report_pdf_carbohydrates;

  /// No description provided for @report_pdf_fats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get report_pdf_fats;

  /// No description provided for @report_pdf_meal_log.
  ///
  /// In en, this message translates to:
  /// **'DETAILED MEAL LOG (Last 7 Days)'**
  String get report_pdf_meal_log;

  /// No description provided for @report_pdf_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get report_pdf_date;

  /// No description provided for @report_pdf_meal_item.
  ///
  /// In en, this message translates to:
  /// **'Meal Item'**
  String get report_pdf_meal_item;

  /// No description provided for @report_pdf_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get report_pdf_type;

  /// No description provided for @report_pdf_footer.
  ///
  /// In en, this message translates to:
  /// **'This report was automatically generated by SnapCal AI.'**
  String get report_pdf_footer;

  /// No description provided for @report_pdf_tagline.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent, stay healthy.'**
  String get report_pdf_tagline;

  /// No description provided for @onboarding_safety_safer_pace.
  ///
  /// In en, this message translates to:
  /// **'We\'ll suggest a safer pace.'**
  String get onboarding_safety_safer_pace;

  /// No description provided for @onboarding_safety_surplus_capped.
  ///
  /// In en, this message translates to:
  /// **'We capped the surplus to keep the plan realistic.'**
  String get onboarding_safety_surplus_capped;

  /// No description provided for @onboarding_safety_floor.
  ///
  /// In en, this message translates to:
  /// **'We kept your target above the minimum safe calorie floor.'**
  String get onboarding_safety_floor;

  /// No description provided for @onboarding_safety_floor_extra.
  ///
  /// In en, this message translates to:
  /// **'{note} Minimum calorie floor applied.'**
  String onboarding_safety_floor_extra(String note);

  /// No description provided for @onboarding_insight_desk.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal keeps your plan realistic while matching a lower-activity routine.'**
  String onboarding_insight_desk(int calories);

  /// No description provided for @onboarding_insight_light.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal gives you a steady target that fits light weekly movement.'**
  String onboarding_insight_light(int calories);

  /// No description provided for @onboarding_insight_athlete.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal supports training demand without pushing the pace too hard.'**
  String onboarding_insight_athlete(int calories);

  /// No description provided for @onboarding_insight_default.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal balances your goal, body size, and current activity level.'**
  String onboarding_insight_default(int calories);

  /// No description provided for @onboarding_tip_desk.
  ///
  /// In en, this message translates to:
  /// **'A 20-minute walk after meals is an easy way to improve consistency.'**
  String get onboarding_tip_desk;

  /// No description provided for @onboarding_tip_light.
  ///
  /// In en, this message translates to:
  /// **'Two extra movement sessions each week will make this target easier to sustain.'**
  String get onboarding_tip_light;

  /// No description provided for @onboarding_tip_athlete.
  ///
  /// In en, this message translates to:
  /// **'Anchor protein across each meal so training recovery stays ahead of appetite swings.'**
  String get onboarding_tip_athlete;

  /// No description provided for @onboarding_tip_bulk.
  ///
  /// In en, this message translates to:
  /// **'Keep most extra calories around training so the surplus works for performance.'**
  String get onboarding_tip_bulk;

  /// No description provided for @onboarding_tip_default.
  ///
  /// In en, this message translates to:
  /// **'Build meals around protein first so the target feels easier to hit.'**
  String get onboarding_tip_default;

  /// No description provided for @paywall_slide_grilled_chicken.
  ///
  /// In en, this message translates to:
  /// **'Grilled Chicken'**
  String get paywall_slide_grilled_chicken;

  /// No description provided for @paywall_slide_rice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get paywall_slide_rice;

  /// No description provided for @paywall_slide_avocado.
  ///
  /// In en, this message translates to:
  /// **'Avocado'**
  String get paywall_slide_avocado;

  /// No description provided for @paywall_slide_toast.
  ///
  /// In en, this message translates to:
  /// **'Toast'**
  String get paywall_slide_toast;

  /// No description provided for @paywall_slide_cherry_tomatoes.
  ///
  /// In en, this message translates to:
  /// **'Cherry Tomatoes'**
  String get paywall_slide_cherry_tomatoes;

  /// No description provided for @paywall_slide_salmon.
  ///
  /// In en, this message translates to:
  /// **'Salmon Fillet'**
  String get paywall_slide_salmon;

  /// No description provided for @paywall_slide_sweet_potato.
  ///
  /// In en, this message translates to:
  /// **'Sweet Potato'**
  String get paywall_slide_sweet_potato;

  /// No description provided for @paywall_slide_broccoli.
  ///
  /// In en, this message translates to:
  /// **'Broccoli'**
  String get paywall_slide_broccoli;

  /// No description provided for @paywall_slide_boiled_eggs.
  ///
  /// In en, this message translates to:
  /// **'Boiled Eggs'**
  String get paywall_slide_boiled_eggs;

  /// No description provided for @paywall_slide_chicken_portion.
  ///
  /// In en, this message translates to:
  /// **'150g'**
  String get paywall_slide_chicken_portion;

  /// No description provided for @paywall_slide_rice_portion.
  ///
  /// In en, this message translates to:
  /// **'130g'**
  String get paywall_slide_rice_portion;

  /// No description provided for @paywall_slide_avocado_portion.
  ///
  /// In en, this message translates to:
  /// **'100g'**
  String get paywall_slide_avocado_portion;

  /// No description provided for @paywall_slide_tomatoes_portion.
  ///
  /// In en, this message translates to:
  /// **'80g'**
  String get paywall_slide_tomatoes_portion;

  /// No description provided for @paywall_slide_salmon_portion.
  ///
  /// In en, this message translates to:
  /// **'150g'**
  String get paywall_slide_salmon_portion;

  /// No description provided for @paywall_slide_sweet_potato_portion.
  ///
  /// In en, this message translates to:
  /// **'130g'**
  String get paywall_slide_sweet_potato_portion;

  /// No description provided for @paywall_slide_broccoli_portion.
  ///
  /// In en, this message translates to:
  /// **'100g'**
  String get paywall_slide_broccoli_portion;

  /// No description provided for @paywall_slide_eggs_portion.
  ///
  /// In en, this message translates to:
  /// **'2 large'**
  String get paywall_slide_eggs_portion;

  /// No description provided for @paywall_slide_toast_portion.
  ///
  /// In en, this message translates to:
  /// **'2 slices'**
  String get paywall_slide_toast_portion;

  /// No description provided for @scan_step_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading food image...'**
  String get scan_step_uploading;

  /// No description provided for @scan_step_scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning visual shapes...'**
  String get scan_step_scanning;

  /// No description provided for @scan_step_ingredients.
  ///
  /// In en, this message translates to:
  /// **'Identifying ingredients...'**
  String get scan_step_ingredients;

  /// No description provided for @scan_step_portions.
  ///
  /// In en, this message translates to:
  /// **'Estimating portion sizes...'**
  String get scan_step_portions;

  /// No description provided for @scan_step_calories.
  ///
  /// In en, this message translates to:
  /// **'Calculating calorie density...'**
  String get scan_step_calories;

  /// No description provided for @scan_step_macros.
  ///
  /// In en, this message translates to:
  /// **'Balancing macronutrients...'**
  String get scan_step_macros;

  /// No description provided for @scan_step_finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing nutrition card...'**
  String get scan_step_finalizing;

  /// No description provided for @common_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get common_camera;

  /// No description provided for @assistant_quick_macros.
  ///
  /// In en, this message translates to:
  /// **'Fix my macros'**
  String get assistant_quick_macros;

  /// No description provided for @assistant_quick_next_meal.
  ///
  /// In en, this message translates to:
  /// **'What should I eat next?'**
  String get assistant_quick_next_meal;

  /// No description provided for @assistant_quick_snack.
  ///
  /// In en, this message translates to:
  /// **'High-protein snack'**
  String get assistant_quick_snack;

  /// No description provided for @assistant_meals_logged_today.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Based on no meals logged today} =1{Based on 1 meal logged today} other{Based on {count} meals logged today}}'**
  String assistant_meals_logged_today(num count);

  /// No description provided for @assistant_ask_coach_header.
  ///
  /// In en, this message translates to:
  /// **'Ask your coach'**
  String get assistant_ask_coach_header;

  /// No description provided for @assistant_brief_today.
  ///
  /// In en, this message translates to:
  /// **'Today\'s coach brief'**
  String get assistant_brief_today;

  /// No description provided for @assistant_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get assistant_live;

  /// No description provided for @assistant_brief_left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get assistant_brief_left;

  /// No description provided for @assistant_protein_gap.
  ///
  /// In en, this message translates to:
  /// **'Protein gap'**
  String get assistant_protein_gap;

  /// No description provided for @assistant_to_goal.
  ///
  /// In en, this message translates to:
  /// **'to goal'**
  String get assistant_to_goal;

  /// No description provided for @assistant_last_meal.
  ///
  /// In en, this message translates to:
  /// **'Last meal'**
  String get assistant_last_meal;

  /// No description provided for @assistant_next_move.
  ///
  /// In en, this message translates to:
  /// **'Next move'**
  String get assistant_next_move;

  /// No description provided for @assistant_no_meals_logged.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet'**
  String get assistant_no_meals_logged;

  /// No description provided for @assistant_action_log_meal.
  ///
  /// In en, this message translates to:
  /// **'Log a meal for precise coaching'**
  String get assistant_action_log_meal;

  /// No description provided for @assistant_action_protein.
  ///
  /// In en, this message translates to:
  /// **'Prioritize protein next'**
  String get assistant_action_protein;

  /// No description provided for @assistant_action_light.
  ///
  /// In en, this message translates to:
  /// **'Keep the next choice light'**
  String get assistant_action_light;

  /// No description provided for @assistant_action_balanced.
  ///
  /// In en, this message translates to:
  /// **'Stay balanced for your next meal'**
  String get assistant_action_balanced;

  /// No description provided for @assistant_analyze_image_prompt.
  ///
  /// In en, this message translates to:
  /// **'Analyze this image.'**
  String get assistant_analyze_image_prompt;

  /// No description provided for @common_items_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String common_items_count(num count);

  /// No description provided for @settings_weight_loss_progress.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss Progress'**
  String get settings_weight_loss_progress;

  /// No description provided for @settings_weight_gain_progress.
  ///
  /// In en, this message translates to:
  /// **'Weight Gain Progress'**
  String get settings_weight_gain_progress;

  /// No description provided for @settings_weight_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get settings_weight_start;

  /// No description provided for @settings_weight_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get settings_weight_current;

  /// No description provided for @settings_weight_target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get settings_weight_target;

  /// No description provided for @settings_goal_reached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get settings_goal_reached;

  /// No description provided for @settings_left_to_reach_target.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} left to reach target'**
  String settings_left_to_reach_target(String amount, String unit);

  /// No description provided for @settings_macro_calorie_split.
  ///
  /// In en, this message translates to:
  /// **'Macro Calorie Split'**
  String get settings_macro_calorie_split;

  /// No description provided for @settings_macro_calorie_split_desc.
  ///
  /// In en, this message translates to:
  /// **'Percentage of total calories contributed by each macro'**
  String get settings_macro_calorie_split_desc;

  /// No description provided for @settings_step_tracking.
  ///
  /// In en, this message translates to:
  /// **'Step Tracking'**
  String get settings_step_tracking;

  /// No description provided for @settings_syncing_activity.
  ///
  /// In en, this message translates to:
  /// **'Syncing activity data...'**
  String get settings_syncing_activity;

  /// No description provided for @settings_sync_now.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get settings_sync_now;

  /// No description provided for @settings_sync_now_desc.
  ///
  /// In en, this message translates to:
  /// **'Refresh steps and estimated calories'**
  String get settings_sync_now_desc;

  /// No description provided for @settings_last_synced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String settings_last_synced(String time);

  /// No description provided for @settings_disconnect_steps.
  ///
  /// In en, this message translates to:
  /// **'Turn off step tracking'**
  String get settings_disconnect_steps;

  /// No description provided for @settings_disconnect_steps_desc.
  ///
  /// In en, this message translates to:
  /// **'Stop listening to phone step updates'**
  String get settings_disconnect_steps_desc;

  /// No description provided for @settings_status_enabled.
  ///
  /// In en, this message translates to:
  /// **'Tracking enabled'**
  String get settings_status_enabled;

  /// No description provided for @settings_status_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get settings_status_denied;

  /// No description provided for @settings_status_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported device'**
  String get settings_status_unsupported;

  /// No description provided for @settings_status_error.
  ///
  /// In en, this message translates to:
  /// **'Tracking error'**
  String get settings_status_error;

  /// No description provided for @settings_status_off.
  ///
  /// In en, this message translates to:
  /// **'Tracking off'**
  String get settings_status_off;

  /// No description provided for @settings_gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settings_gender_male;

  /// No description provided for @settings_gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settings_gender_female;

  /// No description provided for @settings_gender_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settings_gender_other;

  /// No description provided for @settings_age_unit.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get settings_age_unit;

  /// No description provided for @settings_kcal_unit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get settings_kcal_unit;

  /// No description provided for @settings_grams_unit.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get settings_grams_unit;

  /// No description provided for @settings_unit_kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get settings_unit_kg;

  /// No description provided for @settings_unit_lb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get settings_unit_lb;

  /// No description provided for @settings_unit_cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get settings_unit_cm;

  /// No description provided for @settings_unit_in.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get settings_unit_in;

  /// No description provided for @paywall_unlock_snapcal_pro.
  ///
  /// In en, this message translates to:
  /// **'Unlock SnapCal Pro'**
  String get paywall_unlock_snapcal_pro;

  /// No description provided for @paywall_barcode_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Barcode Scanner'**
  String get paywall_barcode_title;

  /// No description provided for @paywall_barcode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Instantly log packaged foods by scanning their barcodes'**
  String get paywall_barcode_subtitle;

  /// No description provided for @paywall_free_scans_used_title.
  ///
  /// In en, this message translates to:
  /// **'You used 3/3 free scans today'**
  String get paywall_free_scans_used_title;

  /// No description provided for @paywall_unlimited_scanning_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock unlimited scanning'**
  String get paywall_unlimited_scanning_subtitle;

  /// No description provided for @paywall_unlimited_scanning_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Unlimited Scanning'**
  String get paywall_unlimited_scanning_title;

  /// No description provided for @paywall_scan_track_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to scan and track all your meals'**
  String get paywall_scan_track_subtitle;

  /// No description provided for @paywall_ai_coaching_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited AI coaching'**
  String get paywall_ai_coaching_title;

  /// No description provided for @paywall_ai_coaching_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get 24/7 personal nutrition guidance'**
  String get paywall_ai_coaching_subtitle;

  /// No description provided for @paywall_smart_planning_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock smart meal planning'**
  String get paywall_smart_planning_title;

  /// No description provided for @paywall_smart_planning_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customized daily plans for your goals'**
  String get paywall_smart_planning_subtitle;

  /// No description provided for @paywall_shopping_lists_title.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated shopping lists'**
  String get paywall_shopping_lists_title;

  /// No description provided for @paywall_shopping_lists_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Save time with smart grocery aggregation'**
  String get paywall_shopping_lists_subtitle;

  /// No description provided for @paywall_progress_journey_title.
  ///
  /// In en, this message translates to:
  /// **'Visual progress journey'**
  String get paywall_progress_journey_title;

  /// No description provided for @paywall_progress_journey_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your body transformation photos'**
  String get paywall_progress_journey_subtitle;

  /// No description provided for @paywall_analytics_title.
  ///
  /// In en, this message translates to:
  /// **'Deep metabolic analytics'**
  String get paywall_analytics_title;

  /// No description provided for @paywall_analytics_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock personalized nutrition trends'**
  String get paywall_analytics_subtitle;

  /// No description provided for @paywall_focused_title.
  ///
  /// In en, this message translates to:
  /// **'100% focused experience'**
  String get paywall_focused_title;

  /// No description provided for @paywall_focused_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads and interruptions'**
  String get paywall_focused_subtitle;

  /// No description provided for @paywall_upgrade_experience_title.
  ///
  /// In en, this message translates to:
  /// **'Upgrade your experience'**
  String get paywall_upgrade_experience_title;

  /// No description provided for @paywall_upgrade_experience_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all premium features today'**
  String get paywall_upgrade_experience_subtitle;

  /// No description provided for @paywall_benefit_unlimited_scans.
  ///
  /// In en, this message translates to:
  /// **'Unlimited scans'**
  String get paywall_benefit_unlimited_scans;

  /// No description provided for @paywall_benefit_ai_guidance.
  ///
  /// In en, this message translates to:
  /// **'AI guidance'**
  String get paywall_benefit_ai_guidance;

  /// No description provided for @paywall_benefit_full_history.
  ///
  /// In en, this message translates to:
  /// **'Full history'**
  String get paywall_benefit_full_history;

  /// No description provided for @paywall_benefit_weekly_reports.
  ///
  /// In en, this message translates to:
  /// **'Weekly reports'**
  String get paywall_benefit_weekly_reports;

  /// No description provided for @paywall_benefit_ad_free.
  ///
  /// In en, this message translates to:
  /// **'Ad-free'**
  String get paywall_benefit_ad_free;

  /// No description provided for @paywall_benefit_smart_planner.
  ///
  /// In en, this message translates to:
  /// **'Smart planner'**
  String get paywall_benefit_smart_planner;

  /// No description provided for @paywall_price_target.
  ///
  /// In en, this message translates to:
  /// **'{price} target'**
  String paywall_price_target(String price);

  /// No description provided for @paywall_billing_monthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get paywall_billing_monthly;

  /// No description provided for @paywall_billing_lifetime.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get paywall_billing_lifetime;

  /// No description provided for @assistant_action_fix_macros.
  ///
  /// In en, this message translates to:
  /// **'Fix today\'s macros'**
  String get assistant_action_fix_macros;

  /// No description provided for @assistant_action_plan_next_meal.
  ///
  /// In en, this message translates to:
  /// **'Plan my next meal'**
  String get assistant_action_plan_next_meal;

  /// No description provided for @assistant_action_light_dinner.
  ///
  /// In en, this message translates to:
  /// **'Suggest a light dinner'**
  String get assistant_action_light_dinner;

  /// No description provided for @assistant_coaching_with_meals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Coaching with no logged meals today} =1{Coaching with today\'s 1 logged meal} other{Coaching with today\'s {count} logged meals}}'**
  String assistant_coaching_with_meals(num count);

  /// No description provided for @assistant_start_new_chat.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat'**
  String get assistant_start_new_chat;

  /// No description provided for @assistant_new_chat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get assistant_new_chat;

  /// No description provided for @assistant_coach_insight.
  ///
  /// In en, this message translates to:
  /// **'Coach insight'**
  String get assistant_coach_insight;

  /// No description provided for @assistant_recipe_estimated_macros.
  ///
  /// In en, this message translates to:
  /// **'Recipe plan with estimated macros'**
  String get assistant_recipe_estimated_macros;

  /// No description provided for @assistant_personalized_from_today.
  ///
  /// In en, this message translates to:
  /// **'Personalized from today\'s nutrition'**
  String get assistant_personalized_from_today;

  /// No description provided for @assistant_step_recipe_plan.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step recipe plan'**
  String get assistant_step_recipe_plan;

  /// No description provided for @assistant_recipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get assistant_recipe;

  /// No description provided for @assistant_ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get assistant_ingredients;

  /// No description provided for @assistant_what_to_do.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get assistant_what_to_do;

  /// No description provided for @assistant_recipe_plan.
  ///
  /// In en, this message translates to:
  /// **'Recipe plan'**
  String get assistant_recipe_plan;

  /// No description provided for @assistant_plan_meal.
  ///
  /// In en, this message translates to:
  /// **'Plan meal'**
  String get assistant_plan_meal;

  /// No description provided for @assistant_adjust_macros.
  ///
  /// In en, this message translates to:
  /// **'Adjust macros'**
  String get assistant_adjust_macros;

  /// No description provided for @assistant_ask_follow_up.
  ///
  /// In en, this message translates to:
  /// **'Ask follow-up'**
  String get assistant_ask_follow_up;

  /// No description provided for @activity_steps_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {steps} steps'**
  String activity_steps_goal(int steps);

  /// No description provided for @activity_unlock_pro_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro activity features'**
  String get activity_unlock_pro_title;

  /// No description provided for @activity_unlock_pro_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Go Pro to unlock dynamic calorie goal adjustment from steps, weekly streaks, manual workout calories, activity score, and insights.'**
  String get activity_unlock_pro_subtitle;

  /// No description provided for @activity_manual_workouts.
  ///
  /// In en, this message translates to:
  /// **'Manual workouts'**
  String get activity_manual_workouts;

  /// No description provided for @activity_no_manual_workouts.
  ///
  /// In en, this message translates to:
  /// **'No manual workouts logged today.'**
  String get activity_no_manual_workouts;

  /// No description provided for @activity_default_workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get activity_default_workout;

  /// No description provided for @activity_add_workout.
  ///
  /// In en, this message translates to:
  /// **'Add workout'**
  String get activity_add_workout;

  /// No description provided for @activity_workout_type.
  ///
  /// In en, this message translates to:
  /// **'Workout type'**
  String get activity_workout_type;

  /// No description provided for @activity_minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get activity_minutes;

  /// No description provided for @activity_save_workout.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get activity_save_workout;

  /// No description provided for @activity_insight_goal_met.
  ///
  /// In en, this message translates to:
  /// **'You averaged {steps} steps this week and are meeting your step goal.'**
  String activity_insight_goal_met(int steps);

  /// No description provided for @activity_insight_goal_gap.
  ///
  /// In en, this message translates to:
  /// **'You averaged {steps} steps this week. A short walk can help close the gap.'**
  String activity_insight_goal_gap(int steps);

  /// No description provided for @common_minutes_short.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String common_minutes_short(int minutes);

  /// No description provided for @common_kcal_value.
  ///
  /// In en, this message translates to:
  /// **'{calories} kcal'**
  String common_kcal_value(int calories);

  /// No description provided for @splash_status_initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing Calorie Intelligence Engine...'**
  String get splash_status_initializing;

  /// No description provided for @splash_status_database.
  ///
  /// In en, this message translates to:
  /// **'Opening encrypted database...'**
  String get splash_status_database;

  /// No description provided for @splash_status_ai_gateways.
  ///
  /// In en, this message translates to:
  /// **'Configuring AI Coach & Gemini gateways...'**
  String get splash_status_ai_gateways;

  /// No description provided for @splash_status_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Calibrating wellness dashboard...'**
  String get splash_status_dashboard;

  /// No description provided for @splash_status_sync_profile.
  ///
  /// In en, this message translates to:
  /// **'Syncing cloud profile...'**
  String get splash_status_sync_profile;

  /// No description provided for @auth_google_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get auth_google_sign_in_failed;

  /// No description provided for @auth_facebook_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Facebook Sign-In failed'**
  String get auth_facebook_sign_in_failed;

  /// No description provided for @auth_google_sign_in_failed_code.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed ({code}). Please try again.'**
  String auth_google_sign_in_failed_code(String code);

  /// No description provided for @auth_firebase_google_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Firebase could not complete Google Sign-In ({code}).'**
  String auth_firebase_google_sign_in_failed(String code);

  /// No description provided for @barcode_unknown_product.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get barcode_unknown_product;

  /// No description provided for @barcode_default_portion.
  ///
  /// In en, this message translates to:
  /// **'per serving/100g'**
  String get barcode_default_portion;

  /// No description provided for @activity_calorie_estimate_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Calories are estimated from steps and may not be exact.'**
  String get activity_calorie_estimate_disclaimer;

  /// No description provided for @activity_estimated_calories.
  ///
  /// In en, this message translates to:
  /// **'Estimated calories'**
  String get activity_estimated_calories;

  /// No description provided for @activity_step_streak.
  ///
  /// In en, this message translates to:
  /// **'Step streak'**
  String get activity_step_streak;

  /// No description provided for @activity_workout_calories.
  ///
  /// In en, this message translates to:
  /// **'Workout calories'**
  String get activity_workout_calories;

  /// No description provided for @activity_score.
  ///
  /// In en, this message translates to:
  /// **'Activity score'**
  String get activity_score;

  /// No description provided for @log_health_title.
  ///
  /// In en, this message translates to:
  /// **'SnapCal Health'**
  String get log_health_title;

  /// No description provided for @log_key_metrics.
  ///
  /// In en, this message translates to:
  /// **'Key metrics'**
  String get log_key_metrics;

  /// No description provided for @log_customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get log_customize;

  /// No description provided for @log_metric_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get log_metric_water;

  /// No description provided for @log_metric_energy_burned.
  ///
  /// In en, this message translates to:
  /// **'Energy burned'**
  String get log_metric_energy_burned;

  /// No description provided for @log_metric_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get log_metric_steps;

  /// No description provided for @log_metric_calories_intake.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get log_metric_calories_intake;

  /// No description provided for @log_macro_unlock_tracking.
  ///
  /// In en, this message translates to:
  /// **'Unlock macro tracking'**
  String get log_macro_unlock_tracking;

  /// No description provided for @log_metric_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get log_metric_carbs;

  /// No description provided for @log_metric_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get log_metric_fat;

  /// No description provided for @log_metric_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get log_metric_protein;

  /// No description provided for @log_metric_steps_unit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get log_metric_steps_unit;

  /// No description provided for @log_period_day.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get log_period_day;

  /// No description provided for @log_period_week.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get log_period_week;

  /// No description provided for @log_period_month.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get log_period_month;

  /// No description provided for @log_period_three_months.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get log_period_three_months;

  /// No description provided for @log_period_year.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get log_period_year;

  /// No description provided for @log_detail_this_day.
  ///
  /// In en, this message translates to:
  /// **'This day'**
  String get log_detail_this_day;

  /// No description provided for @log_detail_this_week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get log_detail_this_week;

  /// No description provided for @log_detail_this_month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get log_detail_this_month;

  /// No description provided for @log_detail_this_three_months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get log_detail_this_three_months;

  /// No description provided for @log_detail_this_year.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get log_detail_this_year;

  /// No description provided for @log_metric_per_day_avg.
  ///
  /// In en, this message translates to:
  /// **'{unit} per day (avg)'**
  String log_metric_per_day_avg(String unit);

  /// No description provided for @log_metric_goal_hit.
  ///
  /// In en, this message translates to:
  /// **'You\'re on track.'**
  String get log_metric_goal_hit;

  /// No description provided for @log_metric_goal_miss.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t hit your goal.'**
  String get log_metric_goal_miss;

  /// No description provided for @log_metric_left.
  ///
  /// In en, this message translates to:
  /// **'{value} left'**
  String log_metric_left(String value);

  /// No description provided for @log_metric_below_range.
  ///
  /// In en, this message translates to:
  /// **'Below range'**
  String get log_metric_below_range;

  /// No description provided for @log_metric_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get log_metric_no_data;

  /// No description provided for @log_metric_locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get log_metric_locked;

  /// No description provided for @log_metric_history_locked.
  ///
  /// In en, this message translates to:
  /// **'Full history is Pro'**
  String get log_metric_history_locked;

  /// No description provided for @log_metric_detail_list_title.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get log_metric_detail_list_title;

  /// No description provided for @common_days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get common_days;

  /// No description provided for @aha_prompt_title.
  ///
  /// In en, this message translates to:
  /// **'You just saved 10 minutes'**
  String get aha_prompt_title;

  /// No description provided for @aha_prompt_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Imagine saving this time every single day. Go Pro for unlimited photo scans and effortless tracking.'**
  String get aha_prompt_subtitle;

  /// No description provided for @aha_prompt_btn.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get aha_prompt_btn;

  /// No description provided for @macro_locked_title.
  ///
  /// In en, this message translates to:
  /// **'Macros are Pro'**
  String get macro_locked_title;

  /// No description provided for @macro_locked_body.
  ///
  /// In en, this message translates to:
  /// **'Unlock protein, carbs, and fat details with SnapCal Pro.'**
  String get macro_locked_body;

  /// No description provided for @macro_unlock_cta.
  ///
  /// In en, this message translates to:
  /// **'Unlock with SnapCal Pro'**
  String get macro_unlock_cta;

  /// No description provided for @macro_locked_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get macro_locked_placeholder;

  /// No description provided for @macro_unlock_card_title.
  ///
  /// In en, this message translates to:
  /// **'Unlock your macro breakdown'**
  String get macro_unlock_card_title;

  /// No description provided for @macro_unlock_card_body.
  ///
  /// In en, this message translates to:
  /// **'See protein, carbs and fat progress for every meal.'**
  String get macro_unlock_card_body;

  /// No description provided for @common_unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get common_unlock;

  /// No description provided for @scan_choice_title.
  ///
  /// In en, this message translates to:
  /// **'Choose scan type'**
  String get scan_choice_title;

  /// No description provided for @scan_choice_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log a meal from a photo or scan packaged food.'**
  String get scan_choice_subtitle;

  /// No description provided for @scan_choice_food_title.
  ///
  /// In en, this message translates to:
  /// **'Scan food'**
  String get scan_choice_food_title;

  /// No description provided for @scan_choice_food_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the camera for instant AI nutrition.'**
  String get scan_choice_food_subtitle;

  /// No description provided for @scan_choice_barcode_title.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scan_choice_barcode_title;

  /// No description provided for @scan_choice_barcode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find packaged food by barcode.'**
  String get scan_choice_barcode_subtitle;

  /// No description provided for @planner_empty_headline.
  ///
  /// In en, this message translates to:
  /// **'Personalized 7-day smart meal planning'**
  String get planner_empty_headline;

  /// No description provided for @planner_empty_body.
  ///
  /// In en, this message translates to:
  /// **'SnapCal builds meals around your calories, macros, preferences, and grocery needs.'**
  String get planner_empty_body;

  /// No description provided for @planner_empty_benefit_adaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive day guidance'**
  String get planner_empty_benefit_adaptive;

  /// No description provided for @planner_empty_benefit_macros.
  ///
  /// In en, this message translates to:
  /// **'Macro-balanced meals'**
  String get planner_empty_benefit_macros;

  /// No description provided for @planner_empty_benefit_grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery list'**
  String get planner_empty_benefit_grocery;

  /// No description provided for @planner_adjust_preferences.
  ///
  /// In en, this message translates to:
  /// **'Adjust preferences'**
  String get planner_adjust_preferences;

  /// No description provided for @planner_meals_unit.
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get planner_meals_unit;

  /// No description provided for @planner_items_unit.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get planner_items_unit;

  /// No description provided for @planner_avg_plan.
  ///
  /// In en, this message translates to:
  /// **'Avg plan'**
  String get planner_avg_plan;

  /// No description provided for @planner_protein_coverage.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get planner_protein_coverage;

  /// No description provided for @planner_guidance_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein is behind; keep the next meal protein-forward.'**
  String get planner_guidance_protein;

  /// No description provided for @planner_guidance_light.
  ///
  /// In en, this message translates to:
  /// **'Calories are tight; keep the next meal lighter.'**
  String get planner_guidance_light;

  /// No description provided for @planner_guidance_balanced.
  ///
  /// In en, this message translates to:
  /// **'You are on pace; follow the planned meals.'**
  String get planner_guidance_balanced;

  /// No description provided for @planner_prep_time.
  ///
  /// In en, this message translates to:
  /// **'Prep time'**
  String get planner_prep_time;

  /// No description provided for @planner_prep_quick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get planner_prep_quick;

  /// No description provided for @planner_prep_balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get planner_prep_balanced;

  /// No description provided for @planner_prep_batch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get planner_prep_batch;

  /// No description provided for @planner_budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get planner_budget;

  /// No description provided for @planner_budget_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get planner_budget_value;

  /// No description provided for @planner_budget_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get planner_budget_standard;

  /// No description provided for @planner_budget_premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get planner_budget_premium;

  /// No description provided for @planner_advanced_preferences.
  ///
  /// In en, this message translates to:
  /// **'Advanced preferences'**
  String get planner_advanced_preferences;

  /// No description provided for @planner_advanced_preferences_body.
  ///
  /// In en, this message translates to:
  /// **'Allergies, dislikes, equipment, servings, and training-day planning are reserved for a later upgrade.'**
  String get planner_advanced_preferences_body;

  /// No description provided for @planner_swap_title.
  ///
  /// In en, this message translates to:
  /// **'Swap meal'**
  String get planner_swap_title;

  /// No description provided for @planner_swap_intent.
  ///
  /// In en, this message translates to:
  /// **'Choose a goal'**
  String get planner_swap_intent;

  /// No description provided for @planner_swap_lower_calorie.
  ///
  /// In en, this message translates to:
  /// **'Lower calorie'**
  String get planner_swap_lower_calorie;

  /// No description provided for @planner_swap_higher_protein.
  ///
  /// In en, this message translates to:
  /// **'Higher protein'**
  String get planner_swap_higher_protein;

  /// No description provided for @planner_swap_faster_prep.
  ///
  /// In en, this message translates to:
  /// **'Faster prep'**
  String get planner_swap_faster_prep;

  /// No description provided for @planner_swap_cheaper.
  ///
  /// In en, this message translates to:
  /// **'Cheaper'**
  String get planner_swap_cheaper;

  /// No description provided for @planner_swap_custom_note.
  ///
  /// In en, this message translates to:
  /// **'Add optional note'**
  String get planner_swap_custom_note;

  /// No description provided for @planner_swap_note_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. chicken, salad, pasta...'**
  String get planner_swap_note_hint;

  /// No description provided for @planner_swap_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate swap'**
  String get planner_swap_generate;

  /// No description provided for @planner_swap_with_note.
  ///
  /// In en, this message translates to:
  /// **'Swap with note'**
  String get planner_swap_with_note;

  /// No description provided for @planner_swap_loading.
  ///
  /// In en, this message translates to:
  /// **'Finding alternative meal...'**
  String get planner_swap_loading;

  /// No description provided for @planner_swap_success.
  ///
  /// In en, this message translates to:
  /// **'Meal replaced with a practical alternative.'**
  String get planner_swap_success;

  /// No description provided for @planner_grocery_ready.
  ///
  /// In en, this message translates to:
  /// **'Already-have checklist'**
  String get planner_grocery_ready;

  /// No description provided for @planner_already_have.
  ///
  /// In en, this message translates to:
  /// **'Already have'**
  String get planner_already_have;

  /// No description provided for @planner_rebalance_notice_light.
  ///
  /// In en, this message translates to:
  /// **'Plan rebalanced: remaining meals are now lighter for today.'**
  String get planner_rebalance_notice_light;

  /// No description provided for @planner_rebalance_notice_protein.
  ///
  /// In en, this message translates to:
  /// **'Plan rebalanced: remaining meals now prioritize protein.'**
  String get planner_rebalance_notice_protein;

  /// No description provided for @planner_today_plan.
  ///
  /// In en, this message translates to:
  /// **'Today\\\'s Plan'**
  String get planner_today_plan;

  /// No description provided for @planner_today_meals.
  ///
  /// In en, this message translates to:
  /// **'Today\\\'s meals'**
  String get planner_today_meals;

  /// No description provided for @planner_planned_unit.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get planner_planned_unit;

  /// No description provided for @planner_planned_for_today.
  ///
  /// In en, this message translates to:
  /// **'Planned for today'**
  String get planner_planned_for_today;

  /// No description provided for @planner_logged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get planner_logged;

  /// No description provided for @planner_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get planner_upcoming;

  /// No description provided for @planner_alert_next_protein.
  ///
  /// In en, this message translates to:
  /// **'Next meal should be protein-forward'**
  String get planner_alert_next_protein;

  /// No description provided for @planner_alert_on_track.
  ///
  /// In en, this message translates to:
  /// **'Plan is on target'**
  String get planner_alert_on_track;

  /// No description provided for @planner_alert_follow_plan.
  ///
  /// In en, this message translates to:
  /// **'Follow the next planned meal'**
  String get planner_alert_follow_plan;

  /// No description provided for @planner_alert_fix_it.
  ///
  /// In en, this message translates to:
  /// **'Fix it'**
  String get planner_alert_fix_it;

  /// No description provided for @planner_week_complete_title.
  ///
  /// In en, this message translates to:
  /// **'This meal plan is complete'**
  String get planner_week_complete_title;

  /// No description provided for @planner_generate_current_week.
  ///
  /// In en, this message translates to:
  /// **'Generate this week\\\'s plan'**
  String get planner_generate_current_week;

  /// No description provided for @settings_milliliters_unit.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get settings_milliliters_unit;

  /// No description provided for @log_customize_metrics_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose which metrics appear on your dashboard'**
  String get log_customize_metrics_desc;

  /// No description provided for @log_metric_full_history_locked.
  ///
  /// In en, this message translates to:
  /// **'Full History Locked'**
  String get log_metric_full_history_locked;

  /// No description provided for @log_metric_full_history_upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro to view history beyond 14 days'**
  String get log_metric_full_history_upgrade;

  /// No description provided for @planner_swap_replacing.
  ///
  /// In en, this message translates to:
  /// **'Replacing: {food}'**
  String planner_swap_replacing(Object food);

  /// No description provided for @planner_rebalance_notice_adjusted.
  ///
  /// In en, this message translates to:
  /// **'Plan rebalanced: {count} remaining \$_temp0 adjusted for today.'**
  String planner_rebalance_notice_adjusted(Object count);

  /// No description provided for @planner_alert_protein_short.
  ///
  /// In en, this message translates to:
  /// **'Protein {grams}g short today'**
  String planner_alert_protein_short(Object grams);

  /// No description provided for @planner_week_complete_body.
  ///
  /// In en, this message translates to:
  /// **'Your last plan ended on {date}. Generate a fresh plan for the current week.'**
  String planner_week_complete_body(Object date);

  /// No description provided for @log_metric_goal_value.
  ///
  /// In en, this message translates to:
  /// **'{value} goal'**
  String log_metric_goal_value(Object value);

  /// No description provided for @onboarding_pace_title.
  ///
  /// In en, this message translates to:
  /// **'Choose your pace'**
  String get onboarding_pace_title;

  /// No description provided for @onboarding_pace_error_target_required.
  ///
  /// In en, this message translates to:
  /// **'Enter a target weight first'**
  String get onboarding_pace_error_target_required;

  /// No description provided for @onboarding_pace_error_pace_required.
  ///
  /// In en, this message translates to:
  /// **'Select a pace to continue'**
  String get onboarding_pace_error_pace_required;

  /// No description provided for @onboarding_pace_gentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get onboarding_pace_gentle;

  /// No description provided for @onboarding_pace_gentle_desc.
  ///
  /// In en, this message translates to:
  /// **'Slower progress, easier to sustain'**
  String get onboarding_pace_gentle_desc;

  /// No description provided for @onboarding_pace_balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get onboarding_pace_balanced;

  /// No description provided for @onboarding_pace_balanced_desc.
  ///
  /// In en, this message translates to:
  /// **'Steady progress with moderate adjustment'**
  String get onboarding_pace_balanced_desc;

  /// No description provided for @onboarding_pace_faster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get onboarding_pace_faster;

  /// No description provided for @onboarding_pace_faster_desc.
  ///
  /// In en, this message translates to:
  /// **'Quick results, more adjustment needed'**
  String get onboarding_pace_faster_desc;

  /// No description provided for @onboarding_pace_target_weight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get onboarding_pace_target_weight;

  /// No description provided for @onboarding_pace_target_date.
  ///
  /// In en, this message translates to:
  /// **'Estimated by {date}'**
  String onboarding_pace_target_date(String date);

  /// No description provided for @onboarding_pace_weekly_rate.
  ///
  /// In en, this message translates to:
  /// **'~{rate} {unit}/week'**
  String onboarding_pace_weekly_rate(String rate, String unit);

  /// No description provided for @onboarding_plan_title.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready'**
  String get onboarding_plan_title;

  /// No description provided for @onboarding_plan_explanation.
  ///
  /// In en, this message translates to:
  /// **'Personalized targets based on your inputs'**
  String get onboarding_plan_explanation;

  /// No description provided for @onboarding_plan_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get onboarding_plan_protein;

  /// No description provided for @onboarding_plan_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get onboarding_plan_carbs;

  /// No description provided for @onboarding_plan_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get onboarding_plan_fat;

  /// No description provided for @onboarding_plan_grams.
  ///
  /// In en, this message translates to:
  /// **'{grams}g'**
  String onboarding_plan_grams(int grams);

  /// No description provided for @onboarding_plan_start.
  ///
  /// In en, this message translates to:
  /// **'Start plan'**
  String get onboarding_plan_start;

  /// No description provided for @onboarding_plan_adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get onboarding_plan_adjust;

  /// No description provided for @onboarding_plan_maintenance_estimate.
  ///
  /// In en, this message translates to:
  /// **'Maintain current weight with tracked nutrition'**
  String get onboarding_plan_maintenance_estimate;

  /// No description provided for @onboarding_goal_summary_lose.
  ///
  /// In en, this message translates to:
  /// **'Lose {rate} {unit}/week'**
  String onboarding_goal_summary_lose(String rate, String unit);

  /// No description provided for @onboarding_goal_summary_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain current weight'**
  String get onboarding_goal_summary_maintain;

  /// No description provided for @onboarding_goal_summary_build.
  ///
  /// In en, this message translates to:
  /// **'Build {rate} {unit}/week'**
  String onboarding_goal_summary_build(String rate, String unit);

  /// No description provided for @onboarding_goal_summary_track.
  ///
  /// In en, this message translates to:
  /// **'Track nutrition without a weight target'**
  String get onboarding_goal_summary_track;

  /// No description provided for @onboarding_safety_zero_loss.
  ///
  /// In en, this message translates to:
  /// **'Your current weight matches your target. We\'ll focus on maintaining with tracked nutrition.'**
  String get onboarding_safety_zero_loss;

  /// No description provided for @onboarding_safety_zero_gain.
  ///
  /// In en, this message translates to:
  /// **'Your current weight matches your target. We\'ll focus on maintaining with tracked nutrition.'**
  String get onboarding_safety_zero_gain;

  /// No description provided for @onboarding_safety_adjusted_detail.
  ///
  /// In en, this message translates to:
  /// **'{originalRate} {unit} was too aggressive. We adjusted to {actualRate} {unit} for safety.'**
  String onboarding_safety_adjusted_detail(
    String originalRate,
    String unit,
    String actualRate,
  );

  /// No description provided for @onboarding_safety_updated_goal.
  ///
  /// In en, this message translates to:
  /// **'Updated target by {date}'**
  String onboarding_safety_updated_goal(String date);

  /// No description provided for @onboarding_safety_adjusted_fallback.
  ///
  /// In en, this message translates to:
  /// **'We adjusted your plan to keep it safe and realistic.'**
  String get onboarding_safety_adjusted_fallback;

  /// No description provided for @onboarding_adjusted_badge.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get onboarding_adjusted_badge;

  /// No description provided for @onboarding_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get onboarding_profile_title;

  /// No description provided for @onboarding_profile_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get onboarding_profile_weight;

  /// No description provided for @onboarding_profile_sex_label.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get onboarding_profile_sex_label;

  /// No description provided for @onboarding_error_sex_required.
  ///
  /// In en, this message translates to:
  /// **'Select your sex to continue'**
  String get onboarding_error_sex_required;

  /// No description provided for @onboarding_error_adult_only.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old'**
  String get onboarding_error_adult_only;

  /// No description provided for @onboarding_already_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get onboarding_already_account;

  /// No description provided for @onboarding_scan_meal_title.
  ///
  /// In en, this message translates to:
  /// **'Scan your meal'**
  String get onboarding_scan_meal_title;

  /// No description provided for @onboarding_scan_scanning.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal...'**
  String get onboarding_scan_scanning;

  /// No description provided for @onboarding_scan_ai_label.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get onboarding_scan_ai_label;

  /// No description provided for @onboarding_scan_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get onboarding_scan_kcal;

  /// No description provided for @onboarding_goal_title.
  ///
  /// In en, this message translates to:
  /// **'What\'s your goal?'**
  String get onboarding_goal_title;

  /// No description provided for @onboarding_goal_lose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight'**
  String get onboarding_goal_lose;

  /// No description provided for @onboarding_goal_lose_desc.
  ///
  /// In en, this message translates to:
  /// **'Calorie deficit to shed body fat'**
  String get onboarding_goal_lose_desc;

  /// No description provided for @onboarding_goal_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get onboarding_goal_maintain;

  /// No description provided for @onboarding_goal_maintain_desc.
  ///
  /// In en, this message translates to:
  /// **'Keep your current weight stable'**
  String get onboarding_goal_maintain_desc;

  /// No description provided for @onboarding_goal_build.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get onboarding_goal_build;

  /// No description provided for @onboarding_goal_build_desc.
  ///
  /// In en, this message translates to:
  /// **'Calorie surplus for lean mass gain'**
  String get onboarding_goal_build_desc;

  /// No description provided for @onboarding_goal_track.
  ///
  /// In en, this message translates to:
  /// **'Track only'**
  String get onboarding_goal_track;

  /// No description provided for @onboarding_goal_track_desc.
  ///
  /// In en, this message translates to:
  /// **'Log meals without a weight target'**
  String get onboarding_goal_track_desc;

  /// No description provided for @onboarding_activity_sitting.
  ///
  /// In en, this message translates to:
  /// **'Sitting'**
  String get onboarding_activity_sitting;

  /// No description provided for @onboarding_activity_sitting_desc.
  ///
  /// In en, this message translates to:
  /// **'Desk job, little exercise'**
  String get onboarding_activity_sitting_desc;

  /// No description provided for @onboarding_activity_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get onboarding_activity_light;

  /// No description provided for @onboarding_activity_light_desc.
  ///
  /// In en, this message translates to:
  /// **'1-3 days of exercise per week'**
  String get onboarding_activity_light_desc;

  /// No description provided for @onboarding_activity_very.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get onboarding_activity_very;

  /// No description provided for @onboarding_activity_very_desc.
  ///
  /// In en, this message translates to:
  /// **'6-7 days of exercise per week'**
  String get onboarding_activity_very_desc;

  /// No description provided for @onboarding_plan_kcal_day.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get onboarding_plan_kcal_day;

  /// No description provided for @onboarding_finish_error.
  ///
  /// In en, this message translates to:
  /// **'Could not create your plan. Please try again.'**
  String get onboarding_finish_error;

  /// No description provided for @onboarding_error_target_lower.
  ///
  /// In en, this message translates to:
  /// **'Target must be lower than current weight'**
  String get onboarding_error_target_lower;

  /// No description provided for @onboarding_error_target_higher.
  ///
  /// In en, this message translates to:
  /// **'Target must be higher than current weight'**
  String get onboarding_error_target_higher;
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
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
