// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SnapCal';

  @override
  String get ads_label => 'ADVERTISEMENT';

  @override
  String get ads_remove_prompt => 'Remove ads — Go Pro';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_next => 'Next';

  @override
  String get common_back => 'Back';

  @override
  String get common_done => 'Done';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_offline_mode => 'Offline Mode';

  @override
  String get error_scan_failed =>
      'Scan failed. Please try again or enter manually.';

  @override
  String get error_barcode_not_found =>
      'Product not found. Please try manual entry.';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_log => 'Log';

  @override
  String get nav_stats => 'Stats';

  @override
  String get nav_profile => 'Profile';

  @override
  String get home_greeting_morning => 'Good Morning';

  @override
  String get home_greeting_afternoon => 'Good Afternoon';

  @override
  String get home_greeting_evening => 'Good Evening';

  @override
  String get home_calories_remaining => 'Calories remaining';

  @override
  String get home_calories_eaten => 'Eaten';

  @override
  String get home_calories_burned => 'Burned';

  @override
  String get home_water_title => 'Water Intake';

  @override
  String home_water_goal(int goal) {
    return 'Goal: ${goal}ml';
  }

  @override
  String get home_recent_meals => 'Recent Meals';

  @override
  String get home_view_all => 'View All';

  @override
  String home_streak_days(int count) {
    return '$count Day Streak';
  }

  @override
  String get home_section_macros => 'Macros';

  @override
  String get home_section_actions => 'Quick actions';

  @override
  String get home_action_log => 'Open log';

  @override
  String get home_action_reports => 'See reports';

  @override
  String get home_sync_prompt => 'Create an account to sync your progress.';

  @override
  String get log_title => 'Daily Log';

  @override
  String get log_subtitle => 'Track your nutrition journey';

  @override
  String get log_entries => 'ENTRIES';

  @override
  String get log_total_kcal => 'TOTAL KCAL';

  @override
  String get log_history => 'MEAL HISTORY';

  @override
  String get log_no_entries_today => 'No logs today';

  @override
  String get log_no_entries_history => 'Empty history';

  @override
  String get log_track_prompt => 'Track your meals to see them here.';

  @override
  String get log_no_data_prompt => 'There is no data for this day.';

  @override
  String get log_return_today => 'Return to Today';

  @override
  String get log_add_manually => 'Add Manually';

  @override
  String log_removed_snackbar(String food) {
    return '$food removed';
  }

  @override
  String get assistant_title => 'AI Coach';

  @override
  String get assistant_status => 'Always active';

  @override
  String get assistant_initial_prompt => 'How can I help you today?';

  @override
  String get assistant_initial_body =>
      'Your personal SnapCal coach is ready to assist with recipes, goals, and nutrition advice.';

  @override
  String get assistant_preparing => 'Preparing your wellness journey...';

  @override
  String get assistant_input_hint => 'Type a message...';

  @override
  String get assistant_input_listening => 'Listening...';

  @override
  String get assistant_needs_connection => 'Assistant needs connection.';

  @override
  String get assistant_clear_title => 'Clear Chat?';

  @override
  String get assistant_clear_body =>
      'This will delete your conversation history with the coach.';

  @override
  String get assistant_clear_confirm => 'Clear';

  @override
  String get assistant_starter_meal_title => 'Meal Ideas';

  @override
  String get assistant_starter_meal_desc => 'High-protein dinners';

  @override
  String get assistant_starter_cal_title => 'Calorie Check';

  @override
  String get assistant_starter_cal_desc => 'How am I doing today?';

  @override
  String get assistant_starter_tips_title => 'Tips';

  @override
  String get assistant_starter_tips_desc => 'Curbing late-night cravings';

  @override
  String get assistant_starter_plans_title => 'Plans';

  @override
  String get assistant_starter_plans_desc => 'Create a 3-day meal plan';

  @override
  String get premium_welcome => 'Welcome to SnapCal Pro! 🎉';

  @override
  String get premium_restore_success => 'Purchases Restored! 🎉';

  @override
  String get premium_restore_empty => 'No previous purchases found.';

  @override
  String get premium_restore_fail => 'Failed to restore purchases.';

  @override
  String get premium_plan_yearly => 'Yearly';

  @override
  String get premium_plan_6months => '6 Months';

  @override
  String get premium_plan_3months => '3 Months';

  @override
  String get premium_plan_2months => '2 Months';

  @override
  String get premium_plan_monthly => 'Monthly';

  @override
  String get premium_plan_weekly => 'Weekly';

  @override
  String get premium_plan_lifetime => 'Lifetime';

  @override
  String get premium_per_month => '/mo';

  @override
  String get premium_free_trial => 'free trial';

  @override
  String get premium_start_trial => 'Start Free Trial';

  @override
  String premium_start_plan(String plan, String price) {
    return 'Start $plan — $price';
  }

  @override
  String get premium_loading => 'Loading...';

  @override
  String get snap_align_food => 'Align food in the frame';

  @override
  String get snap_analyzing => 'Analyzing your meal...';

  @override
  String get snap_retake => 'Retake';

  @override
  String get snap_log_meal => 'Log this meal';

  @override
  String get result_energy => 'Energy';

  @override
  String get result_protein => 'Protein';

  @override
  String get result_carbs => 'Carbs';

  @override
  String get result_fat => 'Fat';

  @override
  String get result_portion => 'Portion Size';

  @override
  String get result_save_success => 'Meal logged successfully!';

  @override
  String get result_health => 'HEALTH';

  @override
  String get result_kcal => 'KCAL';

  @override
  String get result_calories => 'Calories';

  @override
  String get result_macronutrients => 'MACRONUTRIENTS';

  @override
  String get result_logging_portion => 'LOGGING PORTION';

  @override
  String result_ai_estimate(int percent) {
    return '$percent% of AI estimate';
  }

  @override
  String result_daily_goal_info(int percent) {
    return 'This meal is $percent% of your daily energy goal.';
  }

  @override
  String get planner_title => 'Meal Planner';

  @override
  String get planner_smart_title => 'Smart Planner';

  @override
  String get planner_empty_state => 'No plan for today';

  @override
  String get planner_generate => 'Generate AI Plan';

  @override
  String get planner_daily_goal => 'Daily Goal';

  @override
  String get planner_tab_weekly => 'Weekly Plan';

  @override
  String get planner_tab_grocery => 'Grocery List';

  @override
  String get planner_day_mon => 'Mon';

  @override
  String get planner_day_tue => 'Tue';

  @override
  String get planner_day_wed => 'Wed';

  @override
  String get planner_day_thu => 'Thu';

  @override
  String get planner_day_fri => 'Fri';

  @override
  String get planner_day_sat => 'Sat';

  @override
  String get planner_day_sun => 'Sun';

  @override
  String planner_no_meals(Object day) {
    return 'No meals for $day';
  }

  @override
  String planner_regenerate_day(Object day) {
    return 'Regenerate $day?';
  }

  @override
  String get planner_grocery_empty => 'No grocery list yet';

  @override
  String get planner_grocery_pro => 'Grocery list is Pro';

  @override
  String get planner_share => 'Share';

  @override
  String get planner_creating => 'Creating your plan';

  @override
  String get planner_msg_calories => 'Calculating your calorie needs...';

  @override
  String get planner_msg_meals => 'Picking the best meals for your goal...';

  @override
  String get planner_msg_macros => 'Balancing your macros...';

  @override
  String get planner_msg_grocery => 'Building your grocery list...';

  @override
  String get planner_msg_ready => 'Almost ready...';

  @override
  String get error_offline => 'Offline: AI analysis unavailable';

  @override
  String get error_camera => 'Camera unavailable';

  @override
  String get error_generic => 'Something went wrong';

  @override
  String get sync_title => 'Cloud Sync';

  @override
  String get sync_subtitle =>
      'Keep your health data safe across all your devices with an account.';

  @override
  String get sync_benefit_devices => 'Sync across all your devices';

  @override
  String get sync_benefit_progress => 'Never lose your progress';

  @override
  String get sync_benefit_offline => 'Works offline, syncs when online';

  @override
  String get sync_benefit_secure => 'Your data is encrypted & secure';

  @override
  String get sync_google => 'Continue with Google';

  @override
  String get sync_facebook => 'Continue with Facebook';

  @override
  String get sync_email => 'Sign in with Email';

  @override
  String get sync_skip => 'Skip for now';

  @override
  String get splash_tagline => 'Snap. Track. Thrive.';

  @override
  String get notif_breakfast_title => 'Breakfast Reminder';

  @override
  String get notif_breakfast_body => 'Time to log your healthy breakfast!';

  @override
  String get notif_lunch_title => 'Lunch Reminder';

  @override
  String get notif_lunch_body => 'Don\'t forget to track your lunch.';

  @override
  String get notif_dinner_title => 'Dinner Reminder';

  @override
  String get notif_dinner_body => 'End the day strong—log your dinner now.';

  @override
  String get notif_meal_reminders_channel => 'Meal reminders';

  @override
  String get notif_meal_reminders_channel_description =>
      'Reminders to log your daily nutrition.';

  @override
  String get notif_daily_motivation_channel => 'Daily Motivation';

  @override
  String get notif_daily_motivation_channel_description =>
      'Gentle daily nutrition motivation from SnapCal.';

  @override
  String get notif_motivation_1_title => 'Small steps count';

  @override
  String get notif_motivation_1_body =>
      'Log your first meal when you’re ready.';

  @override
  String get notif_motivation_2_title => 'Today starts simple';

  @override
  String get notif_motivation_2_body =>
      'Choose one meal that supports your goal.';

  @override
  String get notif_motivation_3_title => 'One good choice';

  @override
  String get notif_motivation_3_body =>
      'Start with protein, water, or a quick meal log.';

  @override
  String get notif_motivation_4_title => 'You don’t need perfect';

  @override
  String get notif_motivation_4_body => 'Just notice what you eat today.';

  @override
  String get notif_motivation_5_title => 'Fuel first';

  @override
  String get notif_motivation_5_body =>
      'Give your body something useful today.';

  @override
  String get notif_motivation_6_title => 'Make it easy';

  @override
  String get notif_motivation_6_body =>
      'Track one meal. That’s enough to build momentum.';

  @override
  String get notif_motivation_7_title => 'Build the day well';

  @override
  String get notif_motivation_7_body =>
      'A balanced first meal makes the next choice easier.';

  @override
  String get notif_motivation_8_title => 'Your health is daily';

  @override
  String get notif_motivation_8_body =>
      'A small check-in keeps you in control.';

  @override
  String get auth_title => 'Your Journey\nStarts Here';

  @override
  String get auth_subtitle =>
      'Scan, Track, and Master your nutrition in seconds.';

  @override
  String get auth_divider_email => 'Or use email';

  @override
  String get auth_hint_email => 'Email Address';

  @override
  String get auth_hint_password => 'Password';

  @override
  String get auth_btn_signup => 'Create My Account';

  @override
  String get auth_btn_signin => 'Sign In with Email';

  @override
  String get auth_footer_member => 'Already a member? ';

  @override
  String get auth_footer_new => 'New to SnapCal? ';

  @override
  String get auth_action_signin => 'Sign In';

  @override
  String get auth_action_join => 'Join Now';

  @override
  String get auth_msg_success => 'Login successful!';

  @override
  String auth_msg_welcome(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get result_meal_breakfast => 'Breakfast';

  @override
  String get result_meal_lunch => 'Lunch';

  @override
  String get result_meal_dinner => 'Dinner';

  @override
  String get result_meal_snack => 'Snack';

  @override
  String get result_macro_power => 'POWER';

  @override
  String get result_macro_energy => 'ENERGY';

  @override
  String get result_macro_lean => 'LEAN';

  @override
  String get common_hero => 'HERO';

  @override
  String get notif_goal_calories_title => 'Goal Reached! 🚀';

  @override
  String notif_goal_calories_body(Object goal) {
    return 'You\'ve hit your daily calorie goal of $goal kcal!';
  }

  @override
  String get notif_goal_protein_title => 'Protein Goal Met! 💪';

  @override
  String notif_goal_protein_body(Object goal) {
    return 'Great job! You\'ve reached your ${goal}g protein target.';
  }

  @override
  String get notif_goal_alerts_channel => 'Goal alerts';

  @override
  String get notif_goal_alerts_channel_description =>
      'Alerts when you hit your nutrition milestones.';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_save_progress => 'Save progress';

  @override
  String get common_delete_permanently => 'Delete Permanently';

  @override
  String get common_try_again => 'Try Again';

  @override
  String get common_try_reload => 'Try to Reload';

  @override
  String get common_sign_out => 'Sign Out';

  @override
  String get common_sign_out_confirm => 'Are you sure you want to sign out?';

  @override
  String get common_delete_account => 'Delete Account?';

  @override
  String get common_delete_account_confirm =>
      'This action is permanent. All your data will be lost.';

  @override
  String get settings_save_name => 'Save Name';

  @override
  String get settings_log_weight_first =>
      'Log your weight first to recalculate.';

  @override
  String get settings_complete_profile_first =>
      'Complete your profile first (age, gender, height, target).';

  @override
  String get settings_age => 'Age';

  @override
  String get settings_gender => 'Gender';

  @override
  String get settings_units => 'Units';

  @override
  String get settings_weight_unit => 'Weight Unit';

  @override
  String get settings_height_unit => 'Height Unit';

  @override
  String get settings_breakfast_time => 'Breakfast Reminder';

  @override
  String get settings_lunch_time => 'Lunch Reminder';

  @override
  String get settings_dinner_time => 'Dinner Reminder';

  @override
  String get planner_unlock_week => 'Unlock full week';

  @override
  String get planner_upgrade_pro => 'Upgrade to Pro';

  @override
  String get planner_regenerate => 'Regenerate';

  @override
  String get planner_meal_preferences => 'Meal Preferences';

  @override
  String get planner_meals_per_day => 'Meals per day';

  @override
  String get planner_dietary_restriction => 'Dietary restriction';

  @override
  String get planner_cuisine_style => 'Cuisine style';

  @override
  String get planner_generate_plan => 'Generate My Plan';

  @override
  String get assistant_mic_permission =>
      'Microphone permission is required for voice input.';

  @override
  String get assistant_added_to_diary => 'Added to your diary! 🍎';

  @override
  String assistant_plan_updated(String key, String value) {
    return 'Plan updated: $key is now $value';
  }

  @override
  String get water_add_water => 'Add Water';

  @override
  String get water_add => 'Add';

  @override
  String get water_remove => 'Remove';

  @override
  String get water_hydration => 'Hydration';

  @override
  String get water_tracker => 'Hydration Tracker';

  @override
  String water_reached(int amount, int goal) {
    return '$amount of $goal ml reached';
  }

  @override
  String get water_custom => 'Custom';

  @override
  String get water_enter_amount => 'Enter amount';

  @override
  String get progress_tap_to_snap => 'Tap to snap';

  @override
  String get progress_compare_previous => 'Compare with previous';

  @override
  String get log_delete_meal_title => 'Delete Meal Entry?';

  @override
  String get log_delete_meal_body =>
      'This will permanently remove this meal from your diary.';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_display_name => 'Display Name';

  @override
  String get settings_how_to_call => 'How should we call you?';

  @override
  String settings_enter_value(String title) {
    return 'Enter your $title below';
  }

  @override
  String get settings_core_config => 'Core Configuration';

  @override
  String get settings_data_security => 'Data & Security';

  @override
  String get settings_information => 'Information';

  @override
  String get settings_body_profile => 'Body Profile';

  @override
  String get settings_body_profile_sub => 'Update your stats and goals';

  @override
  String get settings_nutrition_goals => 'Nutrition Goals';

  @override
  String get settings_nutrition_goals_sub => 'Daily calorie and macro targets';

  @override
  String get settings_preferences => 'Preferences';

  @override
  String get settings_preferences_sub => 'App theme and notification settings';

  @override
  String get settings_account => 'Account';

  @override
  String get settings_account_sub => 'Membership and profile security';

  @override
  String get settings_data_sync => 'Data & Sync';

  @override
  String get settings_data_sync_sub => 'Export and cloud backup options';

  @override
  String get settings_about => 'About';

  @override
  String get settings_about_sub => 'Terms, privacy, and app info';

  @override
  String get report_title => 'Reports';

  @override
  String get report_subtitle => 'Track your long-term success';

  @override
  String get report_tab_nutrition => 'Nutrition';

  @override
  String get report_tab_body => 'Body';

  @override
  String get report_weekly_review => 'Weekly Review';

  @override
  String get report_monthly_audit => 'Monthly Audit';

  @override
  String get report_failed => 'Failed to generate report';

  @override
  String get paywall_welcome => 'Welcome to SnapCal Pro! 🎉';

  @override
  String get progress_log_progress => 'Log Progress';

  @override
  String get progress_take_photos_desc => 'Take photos to track your journey.';

  @override
  String get progress_front_view => 'Front View';

  @override
  String get progress_side_view => 'Side View';

  @override
  String get progress_saving => 'Saving...';

  @override
  String get progress_save_progress => 'Save Progress';

  @override
  String get progress_comparison => 'Comparison';

  @override
  String progress_weight_diff(String diff) {
    return '$diff kg difference';
  }

  @override
  String get progress_before => 'Before';

  @override
  String get progress_after => 'After';

  @override
  String get progress_missing_photos => 'Missing photos for comparison.';

  @override
  String get progress_front => 'Front';

  @override
  String get progress_side => 'Side';

  @override
  String get progress_failed_camera => 'Failed to open camera.';

  @override
  String get assistant_attached_image => 'Attached image';

  @override
  String get home_body_stats => 'Body Stats';

  @override
  String get log_edit_meal => 'Edit Meal Entry';

  @override
  String get log_log_new_meal => 'Log New Meal';

  @override
  String get log_food_name => 'Food Name';

  @override
  String get log_portion_desc => 'Portion Description';

  @override
  String get log_calories_kcal => 'Calories (kcal)';

  @override
  String get log_save_entry => 'Save Entry';

  @override
  String get log_delete_entry => 'Delete Entry';

  @override
  String get log_food_hint => 'e.g. Avocado Toast';

  @override
  String get log_protein_g => 'Protein (g)';

  @override
  String get log_carbs_g => 'Carbs (g)';

  @override
  String get log_fat_g => 'Fat (g)';

  @override
  String get common_keep_it => 'Keep it';

  @override
  String get planner_target => 'Target';

  @override
  String get planner_setup_desc => 'Quick setup before your plan';

  @override
  String get planner_ai_disclaimer =>
      'This plan is AI-generated for general guidance only.';

  @override
  String get planner_restriction_none => 'None';

  @override
  String get planner_restriction_vegetarian => 'Vegetarian';

  @override
  String get planner_restriction_vegan => 'Vegan';

  @override
  String get planner_restriction_gluten_free => 'Gluten-free';

  @override
  String get planner_restriction_keto => 'Keto';

  @override
  String get planner_restriction_halal => 'Halal';

  @override
  String get planner_cuisine_international => 'International';

  @override
  String get planner_cuisine_south_asian => 'South Asian';

  @override
  String get planner_cuisine_mediterranean => 'Mediterranean';

  @override
  String get planner_cuisine_east_asian => 'East Asian';

  @override
  String get planner_cuisine_american => 'American';

  @override
  String get planner_cuisine_middle_eastern => 'Middle Eastern';

  @override
  String get snap_offline_error => 'AI analysis requires internet connection.';

  @override
  String get home_metric_goal => 'Goal';

  @override
  String get home_metric_meals => 'Meals';

  @override
  String get home_metric_goal_hint => 'Daily target';

  @override
  String get home_metric_meals_hint => 'Logged today';

  @override
  String get home_no_meals_title => 'No meals logged yet';

  @override
  String get home_no_meals_body => 'Start with one quick snap.';

  @override
  String get home_first_meal_cta_title => 'Scan a meal to start today';

  @override
  String get home_first_meal_cta_body =>
      'Use the camera to log calories and macros automatically.';

  @override
  String get home_section_macros_today => 'Macros today';

  @override
  String get home_eaten_progress => 'EATEN';

  @override
  String get home_steps_today => 'steps today';

  @override
  String get home_default_name => 'Friend';

  @override
  String get log_portion_hint => 'e.g. 1 bowl, 200g, 1 slice';

  @override
  String get log_unknown_food => 'Unknown Food';

  @override
  String get home_goal_reached => 'GOAL';

  @override
  String get home_completed => 'COMPLETED';

  @override
  String get home_kcal_left => 'kcal left';

  @override
  String get assistant_typing => 'Coach is typing...';

  @override
  String get assistant_retry => 'Retry';

  @override
  String get assistant_speech_not_available =>
      'Speech recognition not available on this device';

  @override
  String get paywall_pro_plan => 'PRO PLAN';

  @override
  String get paywall_unlock_unlimited => 'Unlock Unlimited';

  @override
  String get paywall_subtitle =>
      'Experience the full power of AI nutrition coaching.';

  @override
  String get paywall_feature_unlimited => 'Unlimited';

  @override
  String get paywall_feature_scans => 'Daily Scans';

  @override
  String get paywall_feature_smart => 'Smart';

  @override
  String get paywall_feature_plans => 'Meal Plans';

  @override
  String get paywall_feature_coach => 'AI Coach';

  @override
  String get paywall_feature_advice => 'Proactive Advice';

  @override
  String get paywall_feature_ads => 'Ad-Free';

  @override
  String get paywall_feature_no_ads => 'Zero Interrupts';

  @override
  String get paywall_best_value => 'BEST VALUE';

  @override
  String get paywall_restore => 'Restore Purchases';

  @override
  String get paywall_purchase_failed => 'Purchase failed. Please try again.';

  @override
  String paywall_save_percent(Object percent) {
    return 'SAVE $percent%';
  }

  @override
  String get paywall_trial_title => 'How your trial works';

  @override
  String get paywall_trial_today => 'Today';

  @override
  String get paywall_trial_today_desc =>
      'You get full access to all Pro features.';

  @override
  String paywall_trial_reminder(Object day) {
    return 'Day $day';
  }

  @override
  String get paywall_trial_reminder_desc =>
      'We send you a reminder that your trial is ending.';

  @override
  String paywall_trial_end(Object day) {
    return 'Day $day';
  }

  @override
  String get paywall_trial_end_desc =>
      'You are charged. Cancel anytime before this to avoid charges.';

  @override
  String get paywall_referral_title => 'Want it for free?';

  @override
  String get paywall_referral_subtitle => 'Invite friends to get bonus scans.';

  @override
  String paywall_then(Object price) {
    return 'Then $price';
  }

  @override
  String get settings_select_language => 'Select Language';

  @override
  String get settings_language_desc =>
      'Choose your preferred language for the interface';

  @override
  String get settings_lang_en_desc => 'Default language';

  @override
  String get settings_lang_ar_desc => 'Arabic (RTL Support)';

  @override
  String get settings_lang_es_desc => 'Spanish';

  @override
  String get settings_lang_fr_desc => 'French';

  @override
  String get settings_appearance => 'App Appearance';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_data_sync_title => 'Data & Sync';

  @override
  String get settings_export_data => 'Export data';

  @override
  String get settings_export_desc => 'Download your meals & metrics';

  @override
  String get settings_cloud_sync_desc => 'Sign in to back up your data';

  @override
  String get settings_about_title => 'About';

  @override
  String get settings_privacy => 'Privacy policy';

  @override
  String get settings_privacy_desc => 'How we handle your data';

  @override
  String get settings_terms => 'Terms of service';

  @override
  String get settings_terms_desc => 'Usage terms & conditions';

  @override
  String get settings_about_snapcal => 'About SnapCal';

  @override
  String get settings_upgrade_pro => 'Upgrade to Pro';

  @override
  String get settings_upgrade_desc => 'Unlock unlimited scans & AI coach';

  @override
  String get planner_free_limit_body => 'Free users can view Mon & Tue only.';

  @override
  String get planner_grocery_empty_body =>
      'Generate a weekly plan first and your grocery list will appear here.';

  @override
  String get planner_grocery_pro_body =>
      'Upgrade to view and manage your weekly grocery list.';

  @override
  String planner_regenerate_body(String day) {
    return 'This will replace $day\'s meals with fresh options.';
  }

  @override
  String get planner_setup_body =>
      'Tell us your goals and we\'ll build a custom 7-day meal plan for you.';

  @override
  String get planner_no_meals_body => 'Try regenerating this day.';

  @override
  String get report_weekly => 'Weekly';

  @override
  String get report_monthly => 'Monthly';

  @override
  String onboarding_step(int current, int total) {
    return 'STEP $current OF $total';
  }

  @override
  String get onboarding_get_started => 'Get Started';

  @override
  String get onboarding_start_journey => 'Start My Journey';

  @override
  String get onboarding_continue => 'Continue';

  @override
  String get onboarding_welcome_title =>
      'Your goal.\nYour calories.\nYour pace.';

  @override
  String get onboarding_welcome_body =>
      'Answer a few quick questions to set your personalized daily calorie target.';

  @override
  String get onboarding_basic_intro_eyebrow => 'PERSONAL DETAILS';

  @override
  String get onboarding_basic_intro_title => 'Set your baseline metrics.';

  @override
  String get onboarding_basic_intro_body =>
      'We use these to calculate your resting metabolic rate (RMR).';

  @override
  String get onboarding_age => 'Age';

  @override
  String get onboarding_age_suffix => 'years';

  @override
  String get onboarding_gender => 'Gender';

  @override
  String get onboarding_male => 'Male';

  @override
  String get onboarding_female => 'Female';

  @override
  String get onboarding_height => 'Height';

  @override
  String get onboarding_weight_intro_eyebrow => 'CURRENT STATUS';

  @override
  String get onboarding_weight_intro_title => 'What do you weigh today?';

  @override
  String get onboarding_weight_intro_body =>
      'This helps us understand your starting point.';

  @override
  String get onboarding_weight_footer =>
      'No judgment. Every journey starts with an honest metric.';

  @override
  String get onboarding_target_intro_eyebrow => 'THE TARGET';

  @override
  String get onboarding_target_intro_title => 'What is your goal weight?';

  @override
  String get onboarding_target_intro_body =>
      'We will structure your calories to hit this target within your timeline.';

  @override
  String get onboarding_target_maintain_title => 'Maintain your weight';

  @override
  String get onboarding_target_maintain_body =>
      'We will build a plan to keep your weight stable while hitting your macros.';

  @override
  String get onboarding_timeline => 'Target Timeline';

  @override
  String onboarding_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Months',
      one: 'Month',
    );
    return '$count $_temp0';
  }

  @override
  String get onboarding_activity_eyebrow => 'LIFESTYLE';

  @override
  String get onboarding_activity_title => 'How active are you?';

  @override
  String get onboarding_activity_body =>
      'Be honest—this is the biggest factor in your calorie burn.';

  @override
  String get onboarding_activity_sedentary => 'Sedentary';

  @override
  String get onboarding_activity_sedentary_desc =>
      'Office job, little exercise';

  @override
  String get onboarding_activity_lightly => 'Lightly Active';

  @override
  String get onboarding_activity_lightly_desc => '1-3 days of exercise/week';

  @override
  String get onboarding_activity_moderately => 'Moderately Active';

  @override
  String get onboarding_activity_moderately_desc => '3-5 days of exercise/week';

  @override
  String get onboarding_activity_active => 'Very Active';

  @override
  String get onboarding_activity_active_desc => '3-5 days/week';

  @override
  String get onboarding_result_eyebrow => 'YOUR PLAN';

  @override
  String get onboarding_result_title => 'Your target is ready.';

  @override
  String get onboarding_result_kcal_day => 'kcal / day';

  @override
  String onboarding_result_reach_by(String date) {
    return 'You\'ll reach your goal by $date';
  }

  @override
  String onboarding_result_pace(String pace, String unit) {
    return 'Pace: $pace $unit / week';
  }

  @override
  String get onboarding_error_age => 'Enter an age between 13 and 100.';

  @override
  String get onboarding_error_height =>
      'Enter a realistic height so we can calculate accurately.';

  @override
  String get onboarding_error_weight => 'Enter a realistic current weight.';

  @override
  String get onboarding_error_goal_weight => 'Enter a realistic goal weight.';

  @override
  String get onboarding_error_timeline =>
      'Adjust your timeline so we can build a valid plan.';

  @override
  String get onboarding_error_generic =>
      'We could not build your plan. Please try again.';

  @override
  String get onboarding_result_loading_eyebrow => 'AI Result';

  @override
  String get onboarding_result_loading_title => 'Building your calorie target.';

  @override
  String get onboarding_result_loading_body =>
      'We are combining your baseline, activity, and goal pace into a plan that is ready to use.';

  @override
  String get onboarding_result_calibrating =>
      'Calibrating your daily target...';

  @override
  String get onboarding_result_error_eyebrow => 'CALCULATION ERROR';

  @override
  String get onboarding_result_error_title => 'We could not finish your plan.';

  @override
  String get onboarding_result_error_body =>
      'Try the last step again or adjust your inputs.';

  @override
  String get onboarding_result_success_eyebrow => 'AI CALIBRATION COMPLETE';

  @override
  String get onboarding_result_success_title => 'Daily target is ready.';

  @override
  String get onboarding_result_success_body =>
      'This number is personalized for your body and target pace.';

  @override
  String get onboarding_result_minor_warning =>
      'Minor detection. Please consult a professional before starting any calorie restriction.';

  @override
  String get onboarding_result_daily_calories => 'DAILY CALORIES';

  @override
  String get onboarding_result_strategy => 'Strategy';

  @override
  String get onboarding_result_recommendation => 'Recommendation';

  @override
  String get onboarding_activity_desk_life => 'Desk Life';

  @override
  String get onboarding_activity_desk_life_desc => 'Little to no exercise';

  @override
  String get onboarding_activity_light_mover => 'Light Mover';

  @override
  String get onboarding_activity_light_mover_desc => '1-3 days/week';

  @override
  String get onboarding_activity_active_title => 'Active';

  @override
  String get onboarding_activity_athlete => 'Athlete';

  @override
  String get onboarding_activity_athlete_desc => '6-7 days/week';

  @override
  String get onboarding_activity_footer =>
      'Active is selected by default. Tap once and we will keep moving.';

  @override
  String get onboarding_feature_target => 'Personal calorie target';

  @override
  String get onboarding_feature_macros => 'Macro split';

  @override
  String get onboarding_feature_insight => 'AI insight';

  @override
  String get planner_meal => 'Meal';

  @override
  String get planner_ingredients => 'Ingredients';

  @override
  String get common_mins => 'mins';

  @override
  String planner_kcal_total(int goal) {
    return '/ $goal kcal';
  }

  @override
  String planner_kcal_over(int delta) {
    return '+$delta over';
  }

  @override
  String planner_kcal_under(int delta) {
    return '$delta under';
  }

  @override
  String get planner_kcal_on_target => 'On target';

  @override
  String get snap_gallery => 'Gallery';

  @override
  String get snap_barcode => 'Barcode';

  @override
  String get snap_pro_unlimited => '∞ Pro';

  @override
  String get snap_bento_plate => 'Bento Plate';

  @override
  String snap_items_detected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 detected on your plate.';
  }

  @override
  String get snap_total_meal => 'TOTAL MEAL';

  @override
  String snap_items_selected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 selected';
  }

  @override
  String get settings_body_profile_title => 'Body Profile';

  @override
  String get settings_body_profile_desc =>
      'Manage your physical metrics and goals.';

  @override
  String get settings_display_name_label => 'Display Name';

  @override
  String get settings_set_name => 'Set name';

  @override
  String get settings_current_weight => 'Current weight';

  @override
  String get settings_set_weight => 'Set weight';

  @override
  String get settings_height => 'Height';

  @override
  String get settings_set_height => 'Set height';

  @override
  String get settings_target_weight => 'Target weight';

  @override
  String get settings_set_target => 'Set target';

  @override
  String get settings_nutrition_goals_title => 'Nutrition Goals';

  @override
  String get settings_daily_calories => 'Daily calories';

  @override
  String get settings_protein => 'Protein';

  @override
  String get settings_carbs => 'Carbs';

  @override
  String get settings_fat => 'Fat';

  @override
  String get settings_optimize_btn => 'Optimize My Nutrition Plan';

  @override
  String get settings_optimizing => 'Optimizing Plan...';

  @override
  String get settings_recalculate_query =>
      'I just optimized my nutrition plan. Please explain why these specific calories and macros were chosen for me based on my profile.';

  @override
  String get settings_guest_account => 'Guest Account';

  @override
  String get settings_sign_in => 'Sign In';

  @override
  String get settings_member => 'SnapCal Member';

  @override
  String get settings_auth_cta => 'Sign up or Sign in';

  @override
  String get settings_preferences_title => 'Preferences';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_meal_reminders => 'Meal reminders';

  @override
  String get settings_daily_motivation => 'Daily motivation';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_account_title => 'Account';

  @override
  String get settings_subscription => 'Subscription';

  @override
  String get settings_pro_active => 'Pro active';

  @override
  String get settings_manage_plan => 'Manage plan';

  @override
  String get settings_create_account => 'Create account';

  @override
  String get settings_sign_out_desc => 'Leave this device session';

  @override
  String get settings_sync_data_desc => 'Sync your data';

  @override
  String get settings_about_app => 'About SnapCal';

  @override
  String get settings_legalese => '© 2026 SnapCal. All rights reserved.';

  @override
  String get onboarding_result_maintain => 'Maintain Current Weight';

  @override
  String onboarding_result_weekly_rate(String rate) {
    return '~$rate kg / week';
  }

  @override
  String get error_connection_title => 'Connection Issue';

  @override
  String get error_connection_body =>
      'Unable to initialize SnapCal. Please check your data or Wi-Fi.';

  @override
  String get error_unexpected_title => 'Something went wrong';

  @override
  String get error_unexpected_body =>
      'We encountered an unexpected error. Our team has been notified and we are working to fix it.';

  @override
  String get report_guest_user => 'Valued User';

  @override
  String get report_avg_calories => 'Avg. Calories';

  @override
  String get report_consistency => 'Consistency';

  @override
  String get report_calorie_trend => 'Calorie trend';

  @override
  String get report_macro_dist => 'Macro distribution';

  @override
  String get report_macro_protein => 'Protein';

  @override
  String get report_macro_carbs => 'Carbs';

  @override
  String get report_macro_fat => 'Fat';

  @override
  String get report_no_weight_title => 'No weight entries yet';

  @override
  String get report_no_weight_body =>
      'Add your first entry so your body trend can start.';

  @override
  String get report_log_weight => 'Log weight';

  @override
  String get report_weight_current => 'Current';

  @override
  String get report_weight_change => 'Change';

  @override
  String get report_progress_timeline => 'Progress Timeline';

  @override
  String get report_progress_gallery => 'Visual body-transformation gallery';

  @override
  String get report_weight_analytics => 'Weight analytics';

  @override
  String get report_recent_history => 'Recent history';

  @override
  String report_body_fat_pct(String percent) {
    return '$percent% Fat';
  }

  @override
  String get weight_hint => 'Weight';

  @override
  String get body_fat_hint => 'Body fat (optional)';

  @override
  String get snap_scan_barcode => 'Scan barcode';

  @override
  String get snap_barcode_hint => 'Place the barcode inside the frame.';

  @override
  String get snap_torch => 'Torch';

  @override
  String get snap_flip => 'Flip';

  @override
  String get settings_health_sync => 'Health Sync';

  @override
  String get settings_health_sync_sub => 'Sync steps and calories burned';

  @override
  String get home_metric_activity => 'Activity';

  @override
  String get home_metric_activity_sync => 'Sync';

  @override
  String get home_metric_activity_enable => 'Enable Health';

  @override
  String get progress_generate_video => 'Generate Journey Video';

  @override
  String get progress_video_failed => 'Video generation failed. Try again.';

  @override
  String get progress_video_min_photos =>
      'Take at least 2 progress photos first!';

  @override
  String get progress_video_share_text =>
      'My SnapCal Transformation Journey! 🚀';

  @override
  String get widget_status_on_track => 'On Track';

  @override
  String get widget_status_over_goal => 'Over Goal';

  @override
  String get widget_status_almost_there => 'Almost There';

  @override
  String get feature_insights_title => 'Weekly Wrap';

  @override
  String get feature_insights_desc => 'Your week in review';

  @override
  String feature_insights_avg_cal(String cal) {
    return 'Avg $cal kcal/day';
  }

  @override
  String feature_insights_on_track(String days) {
    return '$days Days on Track';
  }

  @override
  String get feature_insights_generating => 'Generating Insights...';

  @override
  String get feature_insights_share => 'Share My Week';

  @override
  String get feature_templates_title => 'My Routines';

  @override
  String get feature_templates_empty =>
      'Save your first routine! Log a combo, then tap \'Save as Routine\'.';

  @override
  String get feature_templates_save_prompt => 'Save as Routine?';

  @override
  String get feature_templates_name_hint => 'e.g., Morning Fuel';

  @override
  String get feature_templates_save_btn => 'Save Routine';

  @override
  String get feature_templates_update_btn => 'Update Routine';

  @override
  String get feature_templates_limit_reached =>
      'Free limit reached. Upgrade to Pro for unlimited routines!';

  @override
  String get feature_templates_logged => 'Routine logged successfully!';

  @override
  String get feature_achievements_title => 'Achievements';

  @override
  String feature_achievements_unlocked(String count) {
    return '$count Unlocked';
  }

  @override
  String get achievement_first_flame => 'First Flame';

  @override
  String get achievement_first_flame_desc => 'Log your first meal';

  @override
  String get achievement_consistency_king => 'Consistency King';

  @override
  String get achievement_consistency_king_desc => '7-day logging streak';

  @override
  String get achievement_iron_will => 'Iron Will';

  @override
  String get achievement_iron_will_desc => '30-day logging streak';

  @override
  String get achievement_unstoppable => 'Unstoppable';

  @override
  String get achievement_unstoppable_desc => '100-day logging streak';

  @override
  String get achievement_bullseye => 'Bullseye';

  @override
  String get achievement_bullseye_desc => 'Hit calorie goal exactly';

  @override
  String get achievement_precision_pro => 'Precision Pro';

  @override
  String get achievement_precision_pro_desc =>
      'Hit calorie goal 7 days straight';

  @override
  String get achievement_macro_master => 'Macro Master';

  @override
  String get achievement_macro_master_desc => 'Hit all macros in one day';

  @override
  String get achievement_perfect_week => 'Perfect Week';

  @override
  String get achievement_perfect_week_desc => 'Hit all goals for 7 days';

  @override
  String get achievement_first_sip => 'First Sip';

  @override
  String get achievement_first_sip_desc => 'Log water for the first time';

  @override
  String get achievement_hydration_hero => 'Hydration Hero';

  @override
  String get achievement_hydration_hero_desc => 'Hit water goal 30 days';

  @override
  String get achievement_ocean_mode => 'Ocean Mode';

  @override
  String get achievement_ocean_mode_desc => 'Hit water goal 100 days';

  @override
  String get achievement_first_snap => 'First Snap';

  @override
  String get achievement_first_snap_desc => 'Log 1 meal via camera';

  @override
  String get achievement_snap_master => 'Snap Master';

  @override
  String get achievement_snap_master_desc => 'Log 100 meals';

  @override
  String get achievement_snap_legend => 'Snap Legend';

  @override
  String get achievement_snap_legend_desc => 'Log 500 meals';

  @override
  String get achievement_first_checkin => 'First Check-In';

  @override
  String get achievement_first_checkin_desc => 'Log first body photo';

  @override
  String get achievement_transformation => 'Transformation';

  @override
  String get achievement_transformation_desc => 'Log 10 body photos';

  @override
  String get achievement_journey_video => 'Journey Video';

  @override
  String get achievement_journey_video_desc => 'Generate transformation video';

  @override
  String get feature_achievements_unlocked_title => 'Achievement Unlocked!';

  @override
  String get common_continue => 'Continue';

  @override
  String get feature_insights_subtitle =>
      'Your AI-powered weekly nutrition summary is ready!';

  @override
  String get feature_insights_share_text =>
      'Check out my weekly nutrition summary from SnapCal! 📊';

  @override
  String get settings_guest_title => 'Protect Your Progress';

  @override
  String get settings_guest_subtitle => 'Sign in to sync your data securely.';

  @override
  String get activity_tracking_status => 'TRACKING STATUS';

  @override
  String get activity_active => 'Active';

  @override
  String get activity_description =>
      'Your phone sensors are actively tracking your steps for today\'s calorie burn.';

  @override
  String get activity_authorize_desc =>
      'To track your steps automatically, please authorize activity recognition.';

  @override
  String get activity_authorize_btn => 'Authorize Tracking';

  @override
  String get activity_motivation_low =>
      'Every step counts. Let\'s get moving today!';

  @override
  String get activity_motivation_mid =>
      'You\'re on your way! A quick walk could help you reach your goal.';

  @override
  String get activity_motivation_high =>
      'Almost there! You\'re crushing your activity goals.';

  @override
  String get activity_motivation_elite =>
      'Outstanding! You\'re in the elite active zone today.';

  @override
  String get home_scan_food => 'Scan food';

  @override
  String get home_go_pro => 'Go Pro';

  @override
  String get home_pro_badge => 'PRO';

  @override
  String get settings_upgrade_to_pro => 'UPGRADE TO PRO';

  @override
  String get settings_emerald_badge => 'EMERALD';

  @override
  String get coach_limit_title => 'DAILY LIMIT REACHED';

  @override
  String get coach_limit_subtitle =>
      'Go Premium for unlimited coaching and smarter meal guidance tailored to your goals.';

  @override
  String get coach_limit_btn => 'Upgrade for Unlimited Chat';

  @override
  String get coach_see_options => 'See Subscription Options';

  @override
  String get coach_locked_title => 'Know what to eat next.';

  @override
  String get coach_locked_desc =>
      'AI Coach reads today\'s calories, macros, and goal, then gives clear food advice.';

  @override
  String get coach_preview_meal_title => 'Next meal suggestion';

  @override
  String get coach_preview_meal_body =>
      'Best next meal: grilled chicken rice bowl, around 550 kcal.';

  @override
  String get coach_preview_macro_title => 'Macro correction';

  @override
  String get coach_preview_macro_body =>
      'You still need 45g protein and 120g carbs today.';

  @override
  String get coach_preview_feedback_title => 'Daily progress feedback';

  @override
  String get coach_preview_feedback_body =>
      'You are low on protein. Add eggs, tuna, or Greek yogurt next.';

  @override
  String get report_prompt_title => 'YOUR WEEKLY REPORT IS READY';

  @override
  String get report_prompt_subtitle =>
      'Unlock a deeper look at why some days went over target and how to improve next week.';

  @override
  String get report_prompt_btn => 'Unlock Weekly Report';

  @override
  String get scan_overlay_scanning => 'AI VISION SCANNING';

  @override
  String get scan_overlay_desc =>
      'Detecting ingredients and calculating\nnutritional density with Gemini...';

  @override
  String get scan_overlay_manual => 'LOG MANUALLY';

  @override
  String get report_card_title => 'WEEKLY PROGRESS REPORT';

  @override
  String get report_card_subtitle =>
      'See why some days went over target and get personalized suggestions to fix it.';

  @override
  String get startup_launch_issue => 'Launch Encountered an Issue';

  @override
  String get startup_initialization_slow =>
      'Initialization is taking longer than expected.';

  @override
  String get startup_setup_failed =>
      'Something went wrong while setting up the app. Please try again.';

  @override
  String get startup_retry_launch => 'Retry Launch';

  @override
  String get startup_initialization_error => 'Initialization Error';

  @override
  String get startup_error_body =>
      'The application encountered a startup error. Please try restarting.';

  @override
  String get startup_reload => 'Reload';

  @override
  String get activity_live_tracking => 'LIVE TRACKING';

  @override
  String get activity_stationary => 'STATIONARY';

  @override
  String get activity_steps_today_label => 'STEPS TODAY';

  @override
  String get activity_calories_label => 'CALORIES';

  @override
  String get activity_goal_label => 'GOAL';

  @override
  String get activity_tracking_engine => 'TRACKING ENGINE';

  @override
  String get activity_active_encrypted => 'Active & Encrypted';

  @override
  String get activity_permission_required => 'Permission Required';

  @override
  String get activity_steps_synced => 'Your steps are synced in real-time.';

  @override
  String get activity_enable_tracking =>
      'Enable tracking to see your progress.';

  @override
  String feature_insights_share_error(String error) {
    return 'Error sharing: $error';
  }

  @override
  String get feature_insights_empty => 'No data for this week yet.';

  @override
  String get feature_insights_calorie_trend => 'Calorie Trend';

  @override
  String get feature_insights_ai_coach => 'AI Coach Insights';

  @override
  String get auth_intro_body => 'Your journey to a healthier you starts here.';

  @override
  String get auth_back_to_social => 'Back to Social Login';

  @override
  String get auth_create_account => 'Create account';

  @override
  String get auth_welcome_back_title => 'Welcome back';

  @override
  String get home_welcome_guest => 'Welcome to SnapCal';

  @override
  String get auth_lets_dive => 'Let\'s dive in';

  @override
  String get auth_sign_up_short => 'Sign Up';

  @override
  String get auth_log_in => 'Log In';

  @override
  String get auth_have_account => 'Already have an account? ';

  @override
  String get auth_no_account => 'Don\'t have an account? ';

  @override
  String get common_or => 'or';

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get common_tomorrow => 'Tomorrow';

  @override
  String get common_maybe_later => 'Maybe Later';

  @override
  String get settings_category_body_profile_sub =>
      'Body metrics, units, and target weight';

  @override
  String get settings_category_nutrition_sub =>
      'Calories, protein, carbs, and fat targets';

  @override
  String get settings_category_preferences_sub =>
      'Theme, language, reminders, and meal planning';

  @override
  String get settings_category_achievements_sub =>
      'Streaks, milestones, and progress rewards';

  @override
  String get settings_category_account_sub =>
      'Sign in, profile name, and account controls';

  @override
  String get settings_category_data_sync_sub =>
      'Backup, restore, and local app data';

  @override
  String get settings_category_about_sub =>
      'Version, privacy, terms, and app information';

  @override
  String get home_go_deeper_title => 'Go deeper';

  @override
  String get home_go_deeper_body =>
      'AI day reviews, macro trends, and full history.';

  @override
  String get home_daily_wellness => 'Daily Wellness';

  @override
  String get home_add => 'Add';

  @override
  String get home_daily_score => 'Daily score';

  @override
  String get log_monthly_calendar_soon => 'Monthly calendar coming soon';

  @override
  String get log_today_subtitle => 'Track what you eat today';

  @override
  String get log_review_day => 'Review this day';

  @override
  String get log_scan_food => 'Scan Food';

  @override
  String get feature_templates_saved_meals => 'SAVED MEALS';

  @override
  String get feature_templates_saved_added => 'Saved meal added';

  @override
  String get feature_templates_deleted => 'Routine deleted';

  @override
  String get premium_analysis_title => 'PREMIUM ANALYSIS';

  @override
  String get premium_analysis_body =>
      'Get a better version of this meal based on your goal with AI suggestions.';

  @override
  String get result_meal_name => 'Meal name';

  @override
  String get result_feast => 'Feast';

  @override
  String get result_ai_meal_insight => 'AI meal insight';

  @override
  String get result_ai_meal_body =>
      'Balance this meal with one smart suggestion.';

  @override
  String get result_add_new_item => 'ADD NEW ITEM';

  @override
  String get result_total_calories => 'TOTAL CALORIES';

  @override
  String get result_food_details => 'Food details';

  @override
  String get result_food => 'Food';

  @override
  String get result_portion_label => 'Portion';

  @override
  String get result_add_item => 'Add Item';

  @override
  String get result_nutrition_details => 'Nutrition Details';

  @override
  String get result_unlock_nutrition => 'Unlock nutrition details';

  @override
  String get result_add_to_log => 'Add to Log';

  @override
  String get paywall_cancel_anytime => 'Cancel anytime. No commitment.';

  @override
  String get paywall_terms_conditions => 'Terms & Conditions';

  @override
  String get paywall_trial_7_day => '7-day trial';

  @override
  String get paywall_scan_limit_subtitle =>
      'You used 3/3 free scans today. Unlock unlimited AI food scans and instant calorie breakdowns.';

  @override
  String get paywall_coach_subtitle =>
      'Unlock unlimited coaching, macro guidance, and meal suggestions tailored to your day.';

  @override
  String get paywall_planner_subtitle =>
      'Unlock full weekly plans, grocery lists, preferences, and AI meal regenerations.';

  @override
  String paywall_reports_subtitle(String feature) {
    return 'Unlock deeper analysis, weekly trends, and practical AI suggestions after every $feature.';
  }

  @override
  String get paywall_progress_subtitle =>
      'Unlock more progress photos, comparisons, and transformation tracking beyond the monthly free limit.';

  @override
  String get paywall_ad_removal_subtitle =>
      'Go Pro to remove ads and unlock the full AI nutrition experience.';

  @override
  String get progress_weight_trend => 'Weight Trend';

  @override
  String get progress_log_custom_weight => 'Tap to log your customized weight';

  @override
  String get log_calories_eaten => 'Calories eaten';

  @override
  String log_kcal_over(int amount) {
    return '$amount over';
  }

  @override
  String log_kcal_left(int amount) {
    return '$amount left';
  }

  @override
  String get log_no_details => 'No details logged for this day yet.';

  @override
  String log_over_target_insight(int amount) {
    return 'You logged $amount kcal over target. Review the heavier meals below.';
  }

  @override
  String log_low_protein_insight(int calories) {
    return 'You logged $calories kcal and protein was behind target.';
  }

  @override
  String log_water_behind_insight(int calories) {
    return 'You logged $calories kcal. Water is still behind today.';
  }

  @override
  String log_balanced_day_insight(int calories) {
    return 'You logged $calories kcal with a balanced day so far.';
  }

  @override
  String feature_templates_save_desc(int count) {
    return 'Save these $count items for one-tap logging later.';
  }

  @override
  String get achievement_category_consistency => 'Consistency';

  @override
  String get achievement_category_precision => 'Precision';

  @override
  String get achievement_category_hydration => 'Hydration';

  @override
  String get achievement_category_logging => 'Logging';

  @override
  String get achievement_category_progress => 'Progress';

  @override
  String get achievement_unlocked_label => 'Unlocked';

  @override
  String get report_pdf_title => 'AI NUTRITION REPORT';

  @override
  String report_pdf_user(String name) {
    return 'User: $name';
  }

  @override
  String get report_pdf_weekly_performance => 'WEEKLY PERFORMANCE';

  @override
  String get report_pdf_total_protein => 'Total Protein';

  @override
  String get report_pdf_active_streak => 'Active Streak';

  @override
  String get report_pdf_grams => 'grams';

  @override
  String get report_pdf_days => 'days';

  @override
  String get report_pdf_macro_distribution => 'MACRONUTRIENT DISTRIBUTION';

  @override
  String get report_pdf_nutrient => 'Nutrient';

  @override
  String get report_pdf_total_consumed => 'Total Consumed';

  @override
  String get report_pdf_daily_target => 'Daily Target';

  @override
  String get report_pdf_goal_status => 'Goal Status';

  @override
  String get report_pdf_carbohydrates => 'Carbohydrates';

  @override
  String get report_pdf_fats => 'Fats';

  @override
  String get report_pdf_meal_log => 'DETAILED MEAL LOG (Last 7 Days)';

  @override
  String get report_pdf_date => 'Date';

  @override
  String get report_pdf_meal_item => 'Meal Item';

  @override
  String get report_pdf_type => 'Type';

  @override
  String get report_pdf_footer =>
      'This report was automatically generated by SnapCal AI.';

  @override
  String get report_pdf_tagline => 'Stay consistent, stay healthy.';

  @override
  String get onboarding_safety_safer_pace => 'We\'ll suggest a safer pace.';

  @override
  String get onboarding_safety_surplus_capped =>
      'We capped the surplus to keep the plan realistic.';

  @override
  String get onboarding_safety_floor =>
      'We kept your target above the minimum safe calorie floor.';

  @override
  String onboarding_safety_floor_extra(String note) {
    return '$note Minimum calorie floor applied.';
  }

  @override
  String onboarding_insight_desk(int calories) {
    return '$calories kcal keeps your plan realistic while matching a lower-activity routine.';
  }

  @override
  String onboarding_insight_light(int calories) {
    return '$calories kcal gives you a steady target that fits light weekly movement.';
  }

  @override
  String onboarding_insight_athlete(int calories) {
    return '$calories kcal supports training demand without pushing the pace too hard.';
  }

  @override
  String onboarding_insight_default(int calories) {
    return '$calories kcal balances your goal, body size, and current activity level.';
  }

  @override
  String get onboarding_tip_desk =>
      'A 20-minute walk after meals is an easy way to improve consistency.';

  @override
  String get onboarding_tip_light =>
      'Two extra movement sessions each week will make this target easier to sustain.';

  @override
  String get onboarding_tip_athlete =>
      'Anchor protein across each meal so training recovery stays ahead of appetite swings.';

  @override
  String get onboarding_tip_bulk =>
      'Keep most extra calories around training so the surplus works for performance.';

  @override
  String get onboarding_tip_default =>
      'Build meals around protein first so the target feels easier to hit.';

  @override
  String get paywall_slide_grilled_chicken => 'Grilled Chicken';

  @override
  String get paywall_slide_rice => 'Rice';

  @override
  String get paywall_slide_avocado => 'Avocado';

  @override
  String get paywall_slide_toast => 'Toast';

  @override
  String get paywall_slide_cherry_tomatoes => 'Cherry Tomatoes';

  @override
  String get paywall_slide_salmon => 'Salmon Fillet';

  @override
  String get paywall_slide_sweet_potato => 'Sweet Potato';

  @override
  String get paywall_slide_broccoli => 'Broccoli';

  @override
  String get paywall_slide_boiled_eggs => 'Boiled Eggs';

  @override
  String get paywall_slide_chicken_portion => '150g';

  @override
  String get paywall_slide_rice_portion => '130g';

  @override
  String get paywall_slide_avocado_portion => '100g';

  @override
  String get paywall_slide_tomatoes_portion => '80g';

  @override
  String get paywall_slide_salmon_portion => '150g';

  @override
  String get paywall_slide_sweet_potato_portion => '130g';

  @override
  String get paywall_slide_broccoli_portion => '100g';

  @override
  String get paywall_slide_eggs_portion => '2 large';

  @override
  String get paywall_slide_toast_portion => '2 slices';

  @override
  String get scan_step_uploading => 'Uploading food image...';

  @override
  String get scan_step_scanning => 'Scanning visual shapes...';

  @override
  String get scan_step_ingredients => 'Identifying ingredients...';

  @override
  String get scan_step_portions => 'Estimating portion sizes...';

  @override
  String get scan_step_calories => 'Calculating calorie density...';

  @override
  String get scan_step_macros => 'Balancing macronutrients...';

  @override
  String get scan_step_finalizing => 'Finalizing nutrition card...';

  @override
  String get common_camera => 'Camera';

  @override
  String get assistant_quick_macros => 'Fix my macros';

  @override
  String get assistant_quick_next_meal => 'What should I eat next?';

  @override
  String get assistant_quick_snack => 'High-protein snack';

  @override
  String assistant_meals_logged_today(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Based on $count meals logged today',
      one: 'Based on 1 meal logged today',
      zero: 'Based on no meals logged today',
    );
    return '$_temp0';
  }

  @override
  String get assistant_ask_coach_header => 'Ask your coach';

  @override
  String get assistant_brief_today => 'Today\'s coach brief';

  @override
  String get assistant_live => 'Live';

  @override
  String get assistant_brief_left => 'Left';

  @override
  String get assistant_protein_gap => 'Protein gap';

  @override
  String get assistant_to_goal => 'to goal';

  @override
  String get assistant_last_meal => 'Last meal';

  @override
  String get assistant_next_move => 'Next move';

  @override
  String get assistant_no_meals_logged => 'No meals logged yet';

  @override
  String get assistant_action_log_meal => 'Log a meal for precise coaching';

  @override
  String get assistant_action_protein => 'Prioritize protein next';

  @override
  String get assistant_action_light => 'Keep the next choice light';

  @override
  String get assistant_action_balanced => 'Stay balanced for your next meal';

  @override
  String get assistant_analyze_image_prompt => 'Analyze this image.';

  @override
  String common_items_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get settings_weight_loss_progress => 'Weight Loss Progress';

  @override
  String get settings_weight_gain_progress => 'Weight Gain Progress';

  @override
  String get settings_weight_start => 'Start';

  @override
  String get settings_weight_current => 'Current';

  @override
  String get settings_weight_target => 'Target';

  @override
  String get settings_goal_reached => 'Goal reached! 🎉';

  @override
  String settings_left_to_reach_target(String amount, String unit) {
    return '$amount $unit left to reach target';
  }

  @override
  String get settings_macro_calorie_split => 'Macro Calorie Split';

  @override
  String get settings_macro_calorie_split_desc =>
      'Percentage of total calories contributed by each macro';

  @override
  String get settings_step_tracking => 'Step Tracking';

  @override
  String get settings_syncing_activity => 'Syncing activity data...';

  @override
  String get settings_sync_now => 'Sync now';

  @override
  String get settings_sync_now_desc => 'Refresh steps and estimated calories';

  @override
  String settings_last_synced(String time) {
    return 'Last synced $time';
  }

  @override
  String get settings_disconnect_steps => 'Turn off step tracking';

  @override
  String get settings_disconnect_steps_desc =>
      'Stop listening to phone step updates';

  @override
  String get settings_status_enabled => 'Tracking enabled';

  @override
  String get settings_status_denied => 'Permission denied';

  @override
  String get settings_status_unsupported => 'Unsupported device';

  @override
  String get settings_status_error => 'Tracking error';

  @override
  String get settings_status_off => 'Tracking off';

  @override
  String get settings_gender_male => 'Male';

  @override
  String get settings_gender_female => 'Female';

  @override
  String get settings_gender_other => 'Other';

  @override
  String get settings_age_unit => 'yrs';

  @override
  String get settings_kcal_unit => 'kcal';

  @override
  String get settings_grams_unit => 'g';

  @override
  String get settings_unit_kg => 'kg';

  @override
  String get settings_unit_lb => 'lb';

  @override
  String get settings_unit_cm => 'cm';

  @override
  String get settings_unit_in => 'in';

  @override
  String get paywall_unlock_snapcal_pro => 'Unlock SnapCal Pro';

  @override
  String get paywall_barcode_title => 'Unlock Barcode Scanner';

  @override
  String get paywall_barcode_subtitle =>
      'Instantly log packaged foods by scanning their barcodes';

  @override
  String get paywall_free_scans_used_title => 'You used 3/3 free scans today';

  @override
  String get paywall_unlimited_scanning_subtitle =>
      'Upgrade to unlock unlimited scanning';

  @override
  String get paywall_unlimited_scanning_title => 'Unlock Unlimited Scanning';

  @override
  String get paywall_scan_track_subtitle =>
      'Upgrade to scan and track all your meals';

  @override
  String get paywall_ai_coaching_title => 'Unlock unlimited AI coaching';

  @override
  String get paywall_ai_coaching_subtitle =>
      'Get 24/7 personal nutrition guidance';

  @override
  String get paywall_smart_planning_title => 'Unlock smart meal planning';

  @override
  String get paywall_smart_planning_subtitle =>
      'Customized daily plans for your goals';

  @override
  String get paywall_shopping_lists_title => 'Auto-generated shopping lists';

  @override
  String get paywall_shopping_lists_subtitle =>
      'Save time with smart grocery aggregation';

  @override
  String get paywall_progress_journey_title => 'Visual progress journey';

  @override
  String get paywall_progress_journey_subtitle =>
      'Track your body transformation photos';

  @override
  String get paywall_analytics_title => 'Deep metabolic analytics';

  @override
  String get paywall_analytics_subtitle =>
      'Unlock personalized nutrition trends';

  @override
  String get paywall_focused_title => '100% focused experience';

  @override
  String get paywall_focused_subtitle => 'Remove all ads and interruptions';

  @override
  String get paywall_upgrade_experience_title => 'Upgrade your experience';

  @override
  String get paywall_upgrade_experience_subtitle =>
      'Unlock all premium features today';

  @override
  String get paywall_benefit_unlimited_scans => 'Unlimited scans';

  @override
  String get paywall_benefit_ai_guidance => 'AI guidance';

  @override
  String get paywall_benefit_full_history => 'Full history';

  @override
  String get paywall_benefit_weekly_reports => 'Weekly reports';

  @override
  String get paywall_benefit_ad_free => 'Ad-free';

  @override
  String get paywall_benefit_smart_planner => 'Smart planner';

  @override
  String paywall_price_target(String price) {
    return '$price target';
  }

  @override
  String get paywall_billing_monthly => 'Billed monthly';

  @override
  String get paywall_billing_lifetime => 'One-time payment';

  @override
  String get assistant_action_fix_macros => 'Fix today\'s macros';

  @override
  String get assistant_action_plan_next_meal => 'Plan my next meal';

  @override
  String get assistant_action_light_dinner => 'Suggest a light dinner';

  @override
  String assistant_coaching_with_meals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coaching with today\'s $count logged meals',
      one: 'Coaching with today\'s 1 logged meal',
      zero: 'Coaching with no logged meals today',
    );
    return '$_temp0';
  }

  @override
  String get assistant_start_new_chat => 'Start a new chat';

  @override
  String get assistant_new_chat => 'New chat';

  @override
  String get assistant_coach_insight => 'Coach insight';

  @override
  String get assistant_recipe_estimated_macros =>
      'Recipe plan with estimated macros';

  @override
  String get assistant_personalized_from_today =>
      'Personalized from today\'s nutrition';

  @override
  String get assistant_step_recipe_plan => 'Step-by-step recipe plan';

  @override
  String get assistant_recipe => 'Recipe';

  @override
  String get assistant_ingredients => 'Ingredients';

  @override
  String get assistant_what_to_do => 'What to do';

  @override
  String get assistant_recipe_plan => 'Recipe plan';

  @override
  String get assistant_plan_meal => 'Plan meal';

  @override
  String get assistant_adjust_macros => 'Adjust macros';

  @override
  String get assistant_ask_follow_up => 'Ask follow-up';

  @override
  String activity_steps_goal(int steps) {
    return 'Goal: $steps steps';
  }

  @override
  String get activity_unlock_pro_title => 'Unlock Pro activity features';

  @override
  String get activity_unlock_pro_subtitle =>
      'Go Pro to unlock dynamic calorie goal adjustment from steps, weekly streaks, manual workout calories, activity score, and insights.';

  @override
  String get activity_manual_workouts => 'Manual workouts';

  @override
  String get activity_no_manual_workouts => 'No manual workouts logged today.';

  @override
  String get activity_default_workout => 'Workout';

  @override
  String get activity_add_workout => 'Add workout';

  @override
  String get activity_workout_type => 'Workout type';

  @override
  String get activity_minutes => 'Minutes';

  @override
  String get activity_save_workout => 'Save workout';

  @override
  String activity_insight_goal_met(int steps) {
    return 'You averaged $steps steps this week and are meeting your step goal.';
  }

  @override
  String activity_insight_goal_gap(int steps) {
    return 'You averaged $steps steps this week. A short walk can help close the gap.';
  }

  @override
  String common_minutes_short(int minutes) {
    return '$minutes min';
  }

  @override
  String common_kcal_value(int calories) {
    return '$calories kcal';
  }

  @override
  String get splash_status_initializing =>
      'Initializing Calorie Intelligence Engine...';

  @override
  String get splash_status_database => 'Opening encrypted database...';

  @override
  String get splash_status_ai_gateways =>
      'Configuring AI Coach & Gemini gateways...';

  @override
  String get splash_status_dashboard => 'Calibrating wellness dashboard...';

  @override
  String get splash_status_sync_profile => 'Syncing cloud profile...';

  @override
  String get auth_google_sign_in_failed => 'Google Sign-In failed';

  @override
  String get auth_facebook_sign_in_failed => 'Facebook Sign-In failed';

  @override
  String auth_google_sign_in_failed_code(String code) {
    return 'Google Sign-In failed ($code). Please try again.';
  }

  @override
  String auth_firebase_google_sign_in_failed(String code) {
    return 'Firebase could not complete Google Sign-In ($code).';
  }

  @override
  String get barcode_unknown_product => 'Unknown Product';

  @override
  String get barcode_default_portion => 'per serving/100g';

  @override
  String get activity_calorie_estimate_disclaimer =>
      'Calories are estimated from steps and may not be exact.';

  @override
  String get activity_estimated_calories => 'Estimated calories';

  @override
  String get activity_step_streak => 'Step streak';

  @override
  String get activity_workout_calories => 'Workout calories';

  @override
  String get activity_score => 'Activity score';

  @override
  String get log_health_title => 'SnapCal Health';

  @override
  String get log_key_metrics => 'Key metrics';

  @override
  String get log_customize => 'Customize';

  @override
  String get log_metric_water => 'Water';

  @override
  String get log_metric_energy_burned => 'Energy burned';

  @override
  String get log_metric_steps => 'Steps';

  @override
  String get log_metric_calories_intake => 'Calories';

  @override
  String get log_macro_unlock_tracking => 'Unlock macro tracking';

  @override
  String get log_metric_carbs => 'Carbs';

  @override
  String get log_metric_fat => 'Fat';

  @override
  String get log_metric_protein => 'Protein';

  @override
  String get log_metric_steps_unit => 'steps';

  @override
  String get log_period_day => 'D';

  @override
  String get log_period_week => 'W';

  @override
  String get log_period_month => 'M';

  @override
  String get log_period_three_months => '3M';

  @override
  String get log_period_year => 'Y';

  @override
  String get log_detail_this_day => 'This day';

  @override
  String get log_detail_this_week => 'This week';

  @override
  String get log_detail_this_month => 'This month';

  @override
  String get log_detail_this_three_months => 'Last 3 months';

  @override
  String get log_detail_this_year => 'This year';

  @override
  String log_metric_per_day_avg(String unit) {
    return '$unit per day (avg)';
  }

  @override
  String get log_metric_goal_hit => 'You\'re on track.';

  @override
  String get log_metric_goal_miss => 'You haven\'t hit your goal.';

  @override
  String log_metric_left(String value) {
    return '$value left';
  }

  @override
  String get log_metric_below_range => 'Below range';

  @override
  String get log_metric_no_data => 'No data';

  @override
  String get log_metric_locked => 'Locked';

  @override
  String get log_metric_history_locked => 'Full history is Pro';

  @override
  String get log_metric_detail_list_title => 'This period';

  @override
  String get common_days => 'days';

  @override
  String get aha_prompt_title => 'You just saved 10 minutes';

  @override
  String get aha_prompt_subtitle =>
      'Imagine saving this time every single day. Go Pro for unlimited photo scans and effortless tracking.';

  @override
  String get aha_prompt_btn => 'Go Pro';

  @override
  String get macro_locked_title => 'Macros are Pro';

  @override
  String get macro_locked_body =>
      'Unlock protein, carbs, and fat details with SnapCal Pro.';

  @override
  String get macro_unlock_cta => 'Unlock with SnapCal Pro';

  @override
  String get macro_locked_placeholder => 'Locked';

  @override
  String get macro_unlock_card_title => 'Unlock your macro breakdown';

  @override
  String get macro_unlock_card_body =>
      'See protein, carbs and fat progress for every meal.';

  @override
  String get common_unlock => 'Unlock';

  @override
  String get scan_choice_title => 'Choose scan type';

  @override
  String get scan_choice_subtitle =>
      'Log a meal from a photo or scan packaged food.';

  @override
  String get scan_choice_food_title => 'Scan food';

  @override
  String get scan_choice_food_subtitle =>
      'Use the camera for instant AI nutrition.';

  @override
  String get scan_choice_barcode_title => 'Scan barcode';

  @override
  String get scan_choice_barcode_subtitle => 'Find packaged food by barcode.';

  @override
  String get planner_empty_headline => 'Personalized 7-day smart meal planning';

  @override
  String get planner_empty_body =>
      'SnapCal builds meals around your calories, macros, preferences, and grocery needs.';

  @override
  String get planner_empty_benefit_adaptive => 'Adaptive day guidance';

  @override
  String get planner_empty_benefit_macros => 'Macro-balanced meals';

  @override
  String get planner_empty_benefit_grocery => 'Grocery list';

  @override
  String get planner_adjust_preferences => 'Adjust preferences';

  @override
  String get planner_meals_unit => 'meals';

  @override
  String get planner_items_unit => 'items';

  @override
  String get planner_avg_plan => 'Avg plan';

  @override
  String get planner_protein_coverage => 'Protein';

  @override
  String get planner_guidance_protein =>
      'Protein is behind; keep the next meal protein-forward.';

  @override
  String get planner_guidance_light =>
      'Calories are tight; keep the next meal lighter.';

  @override
  String get planner_guidance_balanced =>
      'You are on pace; follow the planned meals.';

  @override
  String get planner_prep_time => 'Prep time';

  @override
  String get planner_prep_quick => 'Quick';

  @override
  String get planner_prep_balanced => 'Balanced';

  @override
  String get planner_prep_batch => 'Batch';

  @override
  String get planner_budget => 'Budget';

  @override
  String get planner_budget_value => 'Value';

  @override
  String get planner_budget_standard => 'Standard';

  @override
  String get planner_budget_premium => 'Premium';

  @override
  String get planner_advanced_preferences => 'Advanced preferences';

  @override
  String get planner_advanced_preferences_body =>
      'Allergies, dislikes, equipment, servings, and training-day planning are reserved for a later upgrade.';

  @override
  String get planner_swap_title => 'Swap meal';

  @override
  String get planner_swap_intent => 'Choose a goal';

  @override
  String get planner_swap_lower_calorie => 'Lower calorie';

  @override
  String get planner_swap_higher_protein => 'Higher protein';

  @override
  String get planner_swap_faster_prep => 'Faster prep';

  @override
  String get planner_swap_cheaper => 'Cheaper';

  @override
  String get planner_swap_custom_note => 'Add optional note';

  @override
  String get planner_swap_note_hint => 'e.g. chicken, salad, pasta...';

  @override
  String get planner_swap_generate => 'Generate swap';

  @override
  String get planner_swap_with_note => 'Swap with note';

  @override
  String get planner_swap_loading => 'Finding alternative meal...';

  @override
  String get planner_swap_success =>
      'Meal replaced with a practical alternative.';

  @override
  String get planner_grocery_ready => 'Already-have checklist';

  @override
  String get planner_already_have => 'Already have';

  @override
  String get planner_rebalance_notice_light =>
      'Plan rebalanced: remaining meals are now lighter for today.';

  @override
  String get planner_rebalance_notice_protein =>
      'Plan rebalanced: remaining meals now prioritize protein.';

  @override
  String get planner_today_plan => 'Today\\\'s Plan';

  @override
  String get planner_today_meals => 'Today\\\'s meals';

  @override
  String get planner_planned_unit => 'planned';

  @override
  String get planner_planned_for_today => 'Planned for today';

  @override
  String get planner_logged => 'Logged';

  @override
  String get planner_upcoming => 'Upcoming';

  @override
  String get planner_alert_next_protein =>
      'Next meal should be protein-forward';

  @override
  String get planner_alert_on_track => 'Plan is on target';

  @override
  String get planner_alert_follow_plan => 'Follow the next planned meal';

  @override
  String get planner_alert_fix_it => 'Fix it';

  @override
  String get planner_week_complete_title => 'This meal plan is complete';

  @override
  String get planner_generate_current_week => 'Generate this week\\\'s plan';

  @override
  String get settings_milliliters_unit => 'ml';

  @override
  String get log_customize_metrics_desc =>
      'Choose which metrics appear on your dashboard';

  @override
  String get log_metric_full_history_locked => 'Full History Locked';

  @override
  String get log_metric_full_history_upgrade =>
      'Upgrade to Pro to view history beyond 14 days';

  @override
  String planner_swap_replacing(Object food) {
    return 'Replacing: $food';
  }

  @override
  String planner_rebalance_notice_adjusted(Object count) {
    return 'Plan rebalanced: $count remaining \$_temp0 adjusted for today.';
  }

  @override
  String planner_alert_protein_short(Object grams) {
    return 'Protein ${grams}g short today';
  }

  @override
  String planner_week_complete_body(Object date) {
    return 'Your last plan ended on $date. Generate a fresh plan for the current week.';
  }

  @override
  String log_metric_goal_value(Object value) {
    return '$value goal';
  }
}
