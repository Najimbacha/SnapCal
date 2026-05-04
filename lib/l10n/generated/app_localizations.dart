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
