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
}
