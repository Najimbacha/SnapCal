// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سناب كال';

  @override
  String get ads_label => 'إعلان';

  @override
  String get ads_remove_prompt => 'إزالة الإعلانات — كن برو';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_edit => 'تعديل';

  @override
  String get common_skip => 'تخطي';

  @override
  String get common_next => 'التالي';

  @override
  String get common_back => 'رجوع';

  @override
  String get common_done => 'تم';

  @override
  String get common_loading => 'جاري التحميل...';

  @override
  String get common_offline_mode => 'وضع عدم الاتصال';

  @override
  String get error_scan_failed =>
      'فشل المسح. يرجى المحاولة مرة أخرى أو الإدخال يدويًا.';

  @override
  String get error_barcode_not_found =>
      'المنتج غير موجود. يرجى المحاولة يدويًا.';

  @override
  String get nav_home => 'الرئيسية';

  @override
  String get nav_log => 'السجل';

  @override
  String get nav_stats => 'الإحصائيات';

  @override
  String get nav_profile => 'الملف الشخصي';

  @override
  String get home_greeting_morning => 'صباح الخير';

  @override
  String get home_greeting_afternoon => 'طاب مساؤك';

  @override
  String get home_greeting_evening => 'مساء الخير';

  @override
  String get home_calories_remaining => 'السعرات المتبقية';

  @override
  String get home_calories_eaten => 'تم تناولها';

  @override
  String get home_calories_burned => 'تم حرقها';

  @override
  String get home_water_title => 'شرب الماء';

  @override
  String home_water_goal(int goal) {
    return 'الهدف: $goal مل';
  }

  @override
  String get home_recent_meals => 'الوجبات الأخيرة';

  @override
  String get home_view_all => 'عرض الكل';

  @override
  String home_streak_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يوماً',
      few: '$count أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return 'سلسلة من $_temp0';
  }

  @override
  String get home_section_macros => 'العناصر الغذائية';

  @override
  String get home_section_actions => 'إجراءات سريعة';

  @override
  String get home_action_log => 'فتح السجل';

  @override
  String get home_action_reports => 'عرض التقارير';

  @override
  String get home_sync_prompt => 'أنشئ حساباً لمزامنة تقدمك.';

  @override
  String get log_title => 'السجل اليومي';

  @override
  String get log_subtitle => 'تتبع رحلتك الغذائية';

  @override
  String get log_entries => 'المدخلات';

  @override
  String get log_total_kcal => 'إجمالي السعرات';

  @override
  String get log_history => 'سجل الوجبات';

  @override
  String get log_no_entries_today => 'لا توجد سجلات اليوم';

  @override
  String get log_no_entries_history => 'السجل فارغ';

  @override
  String get log_track_prompt => 'قم بتتبع وجباتك لتراها هنا.';

  @override
  String get log_no_data_prompt => 'لا توجد بيانات لهذا اليوم.';

  @override
  String get log_return_today => 'العودة إلى اليوم';

  @override
  String get log_add_manually => 'إضافة يدوياً';

  @override
  String log_removed_snackbar(String food) {
    return 'تم حذف $food';
  }

  @override
  String get assistant_title => 'مدرب الذكاء الاصطناعي';

  @override
  String get assistant_status => 'نشط دائماً';

  @override
  String get assistant_initial_prompt => 'كيف يمكنني مساعدتك اليوم؟';

  @override
  String get assistant_initial_body =>
      'مدرب SnapCal الشخصي جاهز لمساعدتك في الوصفات والأهداف والنصائح الغذائية.';

  @override
  String get assistant_preparing => 'جاري تجهيز رحلتك الصحية...';

  @override
  String get assistant_input_hint => 'اكتب رسالة...';

  @override
  String get assistant_input_listening => 'جاري الاستماع...';

  @override
  String get assistant_needs_connection => 'المساعد يحتاج إلى اتصال بالإنترنت.';

  @override
  String get assistant_clear_title => 'مسح المحادثة؟';

  @override
  String get assistant_clear_body =>
      'سيؤدي هذا إلى حذف سجل المحادثة مع المدرب.';

  @override
  String get assistant_clear_confirm => 'مسح';

  @override
  String get assistant_starter_meal_title => 'أفكار للوجبات';

  @override
  String get assistant_starter_meal_desc => 'عشاء غني بالبروتين';

  @override
  String get assistant_starter_cal_title => 'فحص السعرات';

  @override
  String get assistant_starter_cal_desc => 'كيف حالي اليوم؟';

  @override
  String get assistant_starter_tips_title => 'نصائح';

  @override
  String get assistant_starter_tips_desc => 'كبح الرغبة في الأكل ليلاً';

  @override
  String get assistant_starter_plans_title => 'خطط';

  @override
  String get assistant_starter_plans_desc => 'إنشاء خطة وجبات لمدة 3 أيام';

  @override
  String get premium_welcome => 'مرحباً بك في SnapCal Pro! 🎉';

  @override
  String get premium_restore_success => 'تم استعادة المشتريات! 🎉';

  @override
  String get premium_restore_empty => 'لم يتم العثور على مشتريات سابقة.';

  @override
  String get premium_restore_fail => 'فشل استعادة المشتريات.';

  @override
  String get premium_plan_yearly => 'سنوي';

  @override
  String get premium_plan_6months => '6 أشهر';

  @override
  String get premium_plan_3months => '3 أشهر';

  @override
  String get premium_plan_2months => 'شهرين';

  @override
  String get premium_plan_monthly => 'شهري';

  @override
  String get premium_plan_weekly => 'أسبوعي';

  @override
  String get premium_plan_lifetime => 'مدى الحياة';

  @override
  String get premium_per_month => '/شهرياً';

  @override
  String get premium_free_trial => 'فترة تجريبية مجانية';

  @override
  String get premium_start_trial => 'ابدأ الفترة التجريبية';

  @override
  String premium_start_plan(String plan, String price) {
    return 'ابدأ $plan — $price';
  }

  @override
  String get premium_loading => 'جاري التحميل...';

  @override
  String get snap_align_food => 'ضع الطعام داخل الإطار';

  @override
  String get snap_analyzing => 'جاري تحليل وجبتك...';

  @override
  String get snap_retake => 'إعادة التصوير';

  @override
  String get snap_log_meal => 'تسجيل هذه الوجبة';

  @override
  String get result_energy => 'الطاقة';

  @override
  String get result_protein => 'البروتين';

  @override
  String get result_carbs => 'الكربوهيدرات';

  @override
  String get result_fat => 'الدهون';

  @override
  String get result_portion => 'حجم الحصة';

  @override
  String get result_save_success => 'تم تسجيل الوجبة بنجاح!';

  @override
  String get result_health => 'الصحة';

  @override
  String get result_kcal => 'سعرة';

  @override
  String get result_calories => 'السعرات';

  @override
  String get result_macronutrients => 'العناصر الغذائية الكبرى';

  @override
  String get result_logging_portion => 'حصة التسجيل';

  @override
  String result_ai_estimate(int percent) {
    return '$percent٪ من تقدير الذكاء الاصطناعي';
  }

  @override
  String result_daily_goal_info(int percent) {
    return 'هذه الوجبة تمثل $percent٪ من هدفك اليومي للطاقة.';
  }

  @override
  String get planner_title => 'مخطط الوجبات';

  @override
  String get planner_smart_title => 'المخطط الذكي';

  @override
  String get planner_empty_state => 'لا توجد خطة لليوم';

  @override
  String get planner_generate => 'إنشاء خطة بالذكاء الاصطناعي';

  @override
  String get planner_daily_goal => 'الهدف اليومي';

  @override
  String get planner_tab_weekly => 'الخطة الأسبوعية';

  @override
  String get planner_tab_grocery => 'قائمة التسوق';

  @override
  String get planner_day_mon => 'إثنين';

  @override
  String get planner_day_tue => 'ثلاثاء';

  @override
  String get planner_day_wed => 'أربعاء';

  @override
  String get planner_day_thu => 'خميس';

  @override
  String get planner_day_fri => 'جمعة';

  @override
  String get planner_day_sat => 'سبت';

  @override
  String get planner_day_sun => 'أحد';

  @override
  String planner_no_meals(Object day) {
    return 'لا توجد وجبات ليوم $day';
  }

  @override
  String planner_regenerate_day(Object day) {
    return 'إعادة إنشاء يوم $day؟';
  }

  @override
  String get planner_grocery_empty => 'لا توجد قائمة تسوق بعد';

  @override
  String get planner_grocery_pro => 'قائمة التسوق ميزة للمشتركين';

  @override
  String get planner_share => 'مشاركة';

  @override
  String get planner_creating => 'جاري إنشاء خطتك';

  @override
  String get planner_msg_calories => 'جاري حساب احتياجاتك من السعرات...';

  @override
  String get planner_msg_meals => 'جاري اختيار أفضل الوجبات لهدفك...';

  @override
  String get planner_msg_macros => 'جاري موازنة العناصر الغذائية...';

  @override
  String get planner_msg_grocery => 'جاري بناء قائمة التسوق الخاصة بك...';

  @override
  String get planner_msg_ready => 'أوشكنا على الانتهاء...';

  @override
  String get error_offline => 'غير متصل: تحليل الذكاء الاصطناعي غير متاح';

  @override
  String get error_camera => 'الكاميرا غير متاحة';

  @override
  String get error_generic => 'حدث خطأ ما';

  @override
  String get sync_title => 'مزامنة السحاب';

  @override
  String get sync_subtitle =>
      'حافظ على سلامة بياناتك الصحية عبر جميع أجهزتك باستخدام حساب.';

  @override
  String get sync_benefit_devices => 'المزامنة عبر جميع أجهزتك';

  @override
  String get sync_benefit_progress => 'لا تفقد تقدمك أبداً';

  @override
  String get sync_benefit_offline => 'يعمل بدون إنترنت، يتزامن عند الاتصال';

  @override
  String get sync_benefit_secure => 'بياناتك مشفرة وآمنة';

  @override
  String get sync_google => 'المتابعة باستخدام Google';

  @override
  String get sync_facebook => 'المتابعة باستخدام Facebook';

  @override
  String get sync_email => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get sync_skip => 'تخطي الآن';

  @override
  String get splash_tagline => 'صور. تتبع. ازدهر.';

  @override
  String get notif_breakfast_title => 'تذكير الفطور';

  @override
  String get notif_breakfast_body => 'حان الوقت لتسجيل فطورك الصحي!';

  @override
  String get notif_lunch_title => 'تذكير الغداء';

  @override
  String get notif_lunch_body => 'لا تنسَ تتبع وجبة الغداء.';

  @override
  String get notif_dinner_title => 'تذكير العشاء';

  @override
  String get notif_dinner_body => 'أنهِ يومك بقوة - سجل عشاءك الآن.';

  @override
  String get notif_meal_reminders_channel => 'تذكير الوجبات';

  @override
  String get notif_meal_reminders_channel_description =>
      'تذكيرات لتسجيل تغذيتك اليومية.';

  @override
  String get notif_daily_motivation_channel => 'تحفيز يومي';

  @override
  String get notif_daily_motivation_channel_description =>
      'تحفيز يومي لطيف للتغذية من SnapCal.';

  @override
  String get notif_motivation_1_title => 'خطوة صغيرة تكفي';

  @override
  String get notif_motivation_1_body => 'سجّل أول وجبة عندما تكون جاهزاً.';

  @override
  String get notif_motivation_2_title => 'ابدأ اليوم ببساطة';

  @override
  String get notif_motivation_2_body => 'اختر وجبة واحدة تدعم هدفك.';

  @override
  String get notif_motivation_3_title => 'اختيار جيد واحد';

  @override
  String get notif_motivation_3_body => 'ابدأ ببروتين أو ماء أو تسجيل سريع.';

  @override
  String get notif_motivation_4_title => 'لا تحتاج إلى المثالية';

  @override
  String get notif_motivation_4_body => 'فقط لاحظ ما تأكله اليوم.';

  @override
  String get notif_motivation_5_title => 'غذِّ جسمك أولاً';

  @override
  String get notif_motivation_5_body => 'امنح جسمك شيئاً مفيداً اليوم.';

  @override
  String get notif_motivation_6_title => 'اجعلها سهلة';

  @override
  String get notif_motivation_6_body => 'سجّل وجبة واحدة. هذا يكفي للبداية.';

  @override
  String get notif_motivation_7_title => 'ابنِ يومك جيداً';

  @override
  String get notif_motivation_7_body =>
      'وجبة أولى متوازنة تجعل القرار التالي أسهل.';

  @override
  String get notif_motivation_8_title => 'صحتك عادة يومية';

  @override
  String get notif_motivation_8_body => 'تسجيل صغير يساعدك على البقاء مسيطراً.';

  @override
  String get auth_title => 'رحلتك\nتبدأ هنا';

  @override
  String get auth_subtitle => 'صور، تتبع، واتقن تغذيتك في ثوانٍ.';

  @override
  String get auth_divider_email => 'أو استخدم البريد الإلكتروني';

  @override
  String get auth_hint_email => 'البريد الإلكتروني';

  @override
  String get auth_hint_password => 'كلمة المرور';

  @override
  String get auth_btn_signup => 'إنشاء حسابي';

  @override
  String get auth_btn_signin => 'تسجيل الدخول بالبريد الإلكتروني';

  @override
  String get auth_footer_member => 'عضو بالفعل؟ ';

  @override
  String get auth_footer_new => 'جديد في سناب كال؟ ';

  @override
  String get auth_action_signin => 'تسجيل الدخول';

  @override
  String get auth_action_join => 'انضم الآن';

  @override
  String get auth_msg_success => 'تم تسجيل الدخول بنجاح!';

  @override
  String auth_msg_welcome(String name) {
    return 'مرحباً بك مجدداً، $name!';
  }

  @override
  String get result_meal_breakfast => 'فطور';

  @override
  String get result_meal_lunch => 'غداء';

  @override
  String get result_meal_dinner => 'عشاء';

  @override
  String get result_meal_snack => 'وجبة خفيفة';

  @override
  String get result_macro_power => 'قوة';

  @override
  String get result_macro_energy => 'طاقة';

  @override
  String get result_macro_lean => 'خفيف';

  @override
  String get common_hero => 'بطل';

  @override
  String get notif_goal_calories_title => 'تحقق الهدف! 🚀';

  @override
  String notif_goal_calories_body(Object goal) {
    return 'لقد وصلت إلى هدفك اليومي من السعرات الحرارية: $goal سعرة!';
  }

  @override
  String get notif_goal_protein_title => 'تم تحقيق هدف البروتين! 💪';

  @override
  String notif_goal_protein_body(Object goal) {
    return 'عمل رائع! لقد وصلت إلى هدفك البالغ $goal جرام من البروتين.';
  }

  @override
  String get notif_goal_alerts_channel => 'تنبيهات الأهداف';

  @override
  String get notif_goal_alerts_channel_description =>
      'تنبيهات عند تحقيق أهدافك الغذائية.';

  @override
  String get common_confirm => 'تأكيد';

  @override
  String get common_save_progress => 'حفظ التقدم';

  @override
  String get common_delete_permanently => 'حذف نهائياً';

  @override
  String get common_try_again => 'حاول مرة أخرى';

  @override
  String get common_try_reload => 'حاول إعادة التحميل';

  @override
  String get common_sign_out => 'تسجيل الخروج';

  @override
  String get common_sign_out_confirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get common_delete_account => 'حذف الحساب؟';

  @override
  String get common_delete_account_confirm =>
      'هذا الإجراء نهائي. سيتم فقدان جميع بياناتك.';

  @override
  String get settings_save_name => 'حفظ الاسم';

  @override
  String get settings_log_weight_first => 'سجل وزنك أولاً لإعادة الحساب.';

  @override
  String get settings_complete_profile_first =>
      'أكمل ملفك الشخصي أولاً (العمر، الجنس، الطول، الهدف).';

  @override
  String get settings_age => 'العمر';

  @override
  String get settings_gender => 'الجنس';

  @override
  String get settings_units => 'الوحدات';

  @override
  String get settings_weight_unit => 'وحدة الوزن';

  @override
  String get settings_height_unit => 'وحدة الطول';

  @override
  String get settings_breakfast_time => 'تنبيه الفطور';

  @override
  String get settings_lunch_time => 'تنبيه الغداء';

  @override
  String get settings_dinner_time => 'تنبيه العشاء';

  @override
  String get planner_unlock_week => 'فتح الأسبوع كاملاً';

  @override
  String get planner_upgrade_pro => 'الترقية إلى برو';

  @override
  String get planner_regenerate => 'إعادة التوليد';

  @override
  String get planner_meal_preferences => 'تفضيلات الوجبات';

  @override
  String get planner_meals_per_day => 'عدد الوجبات في اليوم';

  @override
  String get planner_dietary_restriction => 'القيود الغذائية';

  @override
  String get planner_cuisine_style => 'نمط المطبخ';

  @override
  String get planner_generate_plan => 'توليد خطتي';

  @override
  String get assistant_mic_permission => 'مطلوب إذن الميكروفون للإدخال الصوتي.';

  @override
  String get assistant_added_to_diary => 'تمت الإضافة إلى مفكرتك! 🍎';

  @override
  String assistant_plan_updated(String key, String value) {
    return 'تم تحديث الخطة: $key الآن $value';
  }

  @override
  String get water_add_water => 'إضافة ماء';

  @override
  String get water_add => 'إضافة';

  @override
  String get water_remove => 'إزالة';

  @override
  String get water_hydration => 'الترطيب';

  @override
  String get water_tracker => 'متتبع الترطيب';

  @override
  String water_reached(int amount, int goal) {
    return 'تم الوصول إلى $amount من $goal مل';
  }

  @override
  String get water_custom => 'مخصص';

  @override
  String get water_enter_amount => 'أدخل الكمية';

  @override
  String get progress_tap_to_snap => 'انقر للالتقاط';

  @override
  String get progress_compare_previous => 'مقارنة مع السابق';

  @override
  String get log_delete_meal_title => 'حذف وجبة؟';

  @override
  String get log_delete_meal_body => 'سيتم حذف هذه الوجبة نهائياً من مذكرتك.';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_display_name => 'اسم العرض';

  @override
  String get settings_how_to_call => 'كيف يجب أن نناديك؟';

  @override
  String settings_enter_value(String title) {
    return 'أدخل $title أدناه';
  }

  @override
  String get settings_core_config => 'التكوين الأساسي';

  @override
  String get settings_data_security => 'البيانات والأمان';

  @override
  String get settings_information => 'المعلومات';

  @override
  String get settings_body_profile => 'الملف البدني';

  @override
  String get settings_body_profile_sub => 'تحديث إحصائياتك وأهدافك';

  @override
  String get settings_nutrition_goals => 'أهداف التغذية';

  @override
  String get settings_nutrition_goals_sub => 'أهداف السعرات والماكرو اليومية';

  @override
  String get settings_preferences => 'التفضيلات';

  @override
  String get settings_preferences_sub => 'إعدادات المظهر والتنبيهات';

  @override
  String get settings_account => 'الحساب';

  @override
  String get settings_account_sub => 'العضوية وأمان الملف الشخصي';

  @override
  String get settings_data_sync => 'البيانات والمزامنة';

  @override
  String get settings_data_sync_sub => 'خيارات التصدير والنسخ السحابي';

  @override
  String get settings_about => 'حول التطبيق';

  @override
  String get settings_about_sub => 'الشروط، الخصوصية، ومعلومات التطبيق';

  @override
  String get report_title => 'التقارير';

  @override
  String get report_subtitle => 'تتبع نجاحك على المدى الطويل';

  @override
  String get report_tab_nutrition => 'التغذية';

  @override
  String get report_tab_body => 'الجسم';

  @override
  String get report_weekly_review => 'مراجعة أسبوعية';

  @override
  String get report_monthly_audit => 'تدقيق شهري';

  @override
  String get report_failed => 'فشل في إنشاء التقرير';

  @override
  String get paywall_welcome => 'مرحباً بك في سناب كال برو! 🎉';

  @override
  String get progress_log_progress => 'تسجيل التقدم';

  @override
  String get progress_take_photos_desc => 'التقط صورًا لتتبع رحلتك.';

  @override
  String get progress_front_view => 'عرض أمامي';

  @override
  String get progress_side_view => 'عرض جانبي';

  @override
  String get progress_saving => 'جاري الحفظ...';

  @override
  String get progress_save_progress => 'حفظ التقدم';

  @override
  String get progress_comparison => 'مقارنة';

  @override
  String progress_weight_diff(String diff) {
    return 'فرق $diff كجم';
  }

  @override
  String get progress_before => 'قبل';

  @override
  String get progress_after => 'بعد';

  @override
  String get progress_missing_photos => 'صور مفقودة للمقارنة.';

  @override
  String get progress_front => 'أمامي';

  @override
  String get progress_side => 'جانبي';

  @override
  String get progress_failed_camera => 'فشل في فتح الكاميرا.';

  @override
  String get assistant_attached_image => 'صورة مرفقة';

  @override
  String get home_body_stats => 'إحصائيات الجسم';

  @override
  String get log_edit_meal => 'تعديل الوجبة';

  @override
  String get log_log_new_meal => 'تسجيل وجبة جديدة';

  @override
  String get log_food_name => 'اسم الطعام';

  @override
  String get log_portion_desc => 'وصف الحصة';

  @override
  String get log_calories_kcal => 'السعرات (سعرة)';

  @override
  String get log_save_entry => 'حفظ الوجبة';

  @override
  String get log_delete_entry => 'حذف الوجبة';

  @override
  String get log_food_hint => 'مثلاً: توست أفوكادو';

  @override
  String get log_protein_g => 'بروتين (جم)';

  @override
  String get log_carbs_g => 'كربوهيدرات (جم)';

  @override
  String get log_fat_g => 'دهون (جم)';

  @override
  String get common_keep_it => 'الاحتفاظ به';

  @override
  String get planner_target => 'الهدف';

  @override
  String get planner_setup_desc => 'إعداد سريع قبل خطتك';

  @override
  String get planner_ai_disclaimer =>
      'هذه الخطة تم إنشاؤها بواسطة الذكاء الاصطناعي للإرشاد العام فقط.';

  @override
  String get planner_restriction_none => 'لا يوجد';

  @override
  String get planner_restriction_vegetarian => 'نباتي';

  @override
  String get planner_restriction_vegan => 'نباتي صرف';

  @override
  String get planner_restriction_gluten_free => 'خالي من الغلوتين';

  @override
  String get planner_restriction_keto => 'كيتو';

  @override
  String get planner_restriction_halal => 'حلال';

  @override
  String get planner_cuisine_international => 'عالمي';

  @override
  String get planner_cuisine_south_asian => 'جنوب آسيا';

  @override
  String get planner_cuisine_mediterranean => 'البحر الأبيض المتوسط';

  @override
  String get planner_cuisine_east_asian => 'شرق آسيا';

  @override
  String get planner_cuisine_american => 'أمريكي';

  @override
  String get planner_cuisine_middle_eastern => 'الشرق الأوسط';

  @override
  String get snap_offline_error =>
      'يتطلب تحليل الذكاء الاصطناعي اتصالاً بالإنترنت.';

  @override
  String get home_metric_goal => 'الهدف';

  @override
  String get home_metric_meals => 'الوجبات';

  @override
  String get home_metric_goal_hint => 'الهدف اليومي';

  @override
  String get home_metric_meals_hint => 'المسجل اليوم';

  @override
  String get home_no_meals_title => 'لم يتم تسجيل أي وجبات بعد';

  @override
  String get home_no_meals_body => 'ابدأ بالتقاط صورة سريعة.';

  @override
  String get home_first_meal_cta_title => 'امسح وجبة لبدء يومك';

  @override
  String get home_first_meal_cta_body =>
      'استخدم الكاميرا لتسجيل السعرات والعناصر الغذائية تلقائياً.';

  @override
  String get home_section_macros_today => 'عناصر اليوم';

  @override
  String get home_eaten_progress => 'المتناول';

  @override
  String get home_steps_today => 'خطوات اليوم';

  @override
  String get home_default_name => 'صديقي';

  @override
  String get log_portion_hint => 'مثلاً: 1 وعاء، 200 جم، 1 شريحة';

  @override
  String get log_unknown_food => 'طعام غير معروف';

  @override
  String get home_goal_reached => 'الهدف';

  @override
  String get home_completed => 'اكتمل';

  @override
  String get home_kcal_left => 'سعرة متبقية';

  @override
  String get assistant_typing => 'المدرب يكتب...';

  @override
  String get assistant_retry => 'إعادة المحاولة';

  @override
  String get assistant_speech_not_available =>
      'التعرف على الصوت غير متاح على هذا الجهاز';

  @override
  String get paywall_pro_plan => 'خطة برو';

  @override
  String get paywall_unlock_unlimited => 'فتح غير محدود';

  @override
  String get paywall_subtitle =>
      'اختبر القوة الكاملة للتدريب الغذائي بالذكاء الاصطناعي.';

  @override
  String get paywall_feature_unlimited => 'غير محدود';

  @override
  String get paywall_feature_scans => 'عمليات مسح يومية';

  @override
  String get paywall_feature_smart => 'ذكاء';

  @override
  String get paywall_feature_plans => 'خطط وجبات';

  @override
  String get paywall_feature_coach => 'مدرب ذكاء اصطناعي';

  @override
  String get paywall_feature_advice => 'نصائح استباقية';

  @override
  String get paywall_feature_ads => 'بدون إعلانات';

  @override
  String get paywall_feature_no_ads => 'بدون مقاطعة';

  @override
  String get paywall_best_value => 'أفضل قيمة';

  @override
  String get paywall_restore => 'استعادة المشتريات';

  @override
  String get paywall_purchase_failed => 'فشلت عملية الشراء. حاول مرة أخرى.';

  @override
  String paywall_save_percent(Object percent) {
    return 'وفر $percent٪';
  }

  @override
  String get paywall_trial_title => 'كيف تعمل الفترة التجريبية';

  @override
  String get paywall_trial_today => 'اليوم';

  @override
  String get paywall_trial_today_desc => 'تحصل على وصول كامل لجميع ميزات برو.';

  @override
  String paywall_trial_reminder(Object day) {
    return 'اليوم $day';
  }

  @override
  String get paywall_trial_reminder_desc =>
      'سنرسل لك تذكيراً بأن الفترة التجريبية تقترب من نهايتها.';

  @override
  String paywall_trial_end(Object day) {
    return 'اليوم $day';
  }

  @override
  String get paywall_trial_end_desc =>
      'سيتم الخصم. يمكنك الإلغاء في أي وقت قبل ذلك لتجنب الرسوم.';

  @override
  String get paywall_referral_title => 'تريد الحصول عليه مجاناً؟';

  @override
  String get paywall_referral_subtitle =>
      'ادعُ أصدقاءك للحصول على عمليات مسح إضافية.';

  @override
  String paywall_then(Object price) {
    return 'ثم $price';
  }

  @override
  String get settings_select_language => 'اختر اللغة';

  @override
  String get settings_language_desc => 'اختر لغتك المفضلة للواجهة';

  @override
  String get settings_lang_en_desc => 'اللغة الافتراضية';

  @override
  String get settings_lang_ar_desc => 'العربية (دعم RTL)';

  @override
  String get settings_lang_es_desc => 'الإسبانية';

  @override
  String get settings_lang_fr_desc => 'الفرنسية';

  @override
  String get settings_appearance => 'مظهر التطبيق';

  @override
  String get settings_theme_system => 'النظام';

  @override
  String get settings_theme_light => 'فاتح';

  @override
  String get settings_theme_dark => 'داكن';

  @override
  String get settings_data_sync_title => 'البيانات والمزامنة';

  @override
  String get settings_export_data => 'تصدير البيانات';

  @override
  String get settings_export_desc => 'تحميل وجباتك وإحصائياتك';

  @override
  String get settings_cloud_sync_desc => 'سجل الدخول لنسخ بياناتك احتياطياً';

  @override
  String get settings_about_title => 'حول';

  @override
  String get settings_privacy => 'سياسة الخصوصية';

  @override
  String get settings_privacy_desc => 'كيف نتعامل مع بياناتك';

  @override
  String get settings_terms => 'شروط الخدمة';

  @override
  String get settings_terms_desc => 'شروط وأحكام الاستخدام';

  @override
  String get settings_about_snapcal => 'حول سناب كال';

  @override
  String get settings_upgrade_pro => 'الترقية إلى برو';

  @override
  String get settings_upgrade_desc =>
      'فتح عمليات مسح غير محدودة ومدرب الذكاء الاصطناعي';

  @override
  String get planner_free_limit_body =>
      'يمكن لمستخدمي النسخة المجانية عرض الإثنين والثلاثاء فقط.';

  @override
  String get planner_grocery_empty_body =>
      'أنشئ خطة أسبوعية أولاً وستظهر قائمة التسوق الخاصة بك هنا.';

  @override
  String get planner_grocery_pro_body =>
      'قم بالترقية لعرض وإدارة قائمة التسوق الأسبوعية الخاصة بك.';

  @override
  String planner_regenerate_body(String day) {
    return 'سيؤدي هذا إلى استبدال وجبات يوم $day بخيارات جديدة.';
  }

  @override
  String get planner_setup_body =>
      'أخبرنا بأهدافك وسنبني لك خطة وجبات مخصصة لمدة 7 أيام.';

  @override
  String get planner_no_meals_body => 'حاول إعادة إنشاء هذا اليوم.';

  @override
  String get report_weekly => 'أسبوعي';

  @override
  String get report_monthly => 'شهري';

  @override
  String onboarding_step(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onboarding_get_started => 'ابدأ الآن';

  @override
  String get onboarding_start_journey => 'ابدأ رحلتي';

  @override
  String get onboarding_continue => 'استمرار';

  @override
  String get onboarding_welcome_title => 'هدفك.\nسعراتك.\nوتيرتك.';

  @override
  String get onboarding_welcome_body =>
      'أجب على بعض الأسئلة السريعة لتحديد هدفك اليومي الشخصي من السعرات الحرارية.';

  @override
  String get onboarding_basic_intro_eyebrow => 'التفاصيل الشخصية';

  @override
  String get onboarding_basic_intro_title => 'حدد قياساتك الأساسية.';

  @override
  String get onboarding_basic_intro_body =>
      'نحن نستخدم هذه لحساب معدل الأيض الأساسي (RMR).';

  @override
  String get onboarding_age => 'العمر';

  @override
  String get onboarding_age_suffix => 'سنة';

  @override
  String get onboarding_gender => 'الجنس';

  @override
  String get onboarding_male => 'ذكر';

  @override
  String get onboarding_female => 'أنثى';

  @override
  String get onboarding_height => 'الطول';

  @override
  String get onboarding_weight_intro_eyebrow => 'الوضع الحالي';

  @override
  String get onboarding_weight_intro_title => 'كم تزن اليوم؟';

  @override
  String get onboarding_weight_intro_body => 'هذا يساعدنا على فهم نقطة بدايتك.';

  @override
  String get onboarding_weight_footer => 'لا حكم هنا. كل رحلة تبدأ بقياس صادق.';

  @override
  String get onboarding_target_intro_eyebrow => 'الهدف';

  @override
  String get onboarding_target_intro_title => 'ما هو وزنك المستهدف؟';

  @override
  String get onboarding_target_intro_body =>
      'سنقوم ببناء سعراتك للوصول إلى هذا الهدف ضمن جدولك الزمني.';

  @override
  String get onboarding_target_maintain_title => 'الحفاظ على وزنك';

  @override
  String get onboarding_target_maintain_body =>
      'سنبني خطة للحفاظ على استقرار وزنك مع تحقيق العناصر الغذائية الخاصة بك.';

  @override
  String get onboarding_timeline => 'الجدول الزمني للهدف';

  @override
  String onboarding_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهر',
      many: '$count شهراً',
      few: '$count أشهر',
      two: 'شهران',
      one: 'شهر واحد',
      zero: '0 شهر',
    );
    return '$_temp0';
  }

  @override
  String get onboarding_activity_eyebrow => 'نمط الحياة';

  @override
  String get onboarding_activity_title => 'ما مدى نشاطك؟';

  @override
  String get onboarding_activity_body =>
      'كن صادقاً - هذا هو أكبر عامل في حرق السعرات الحرارية لديك.';

  @override
  String get onboarding_activity_sedentary => 'خامل';

  @override
  String get onboarding_activity_sedentary_desc => 'وظيفة مكتبية، تمرين قليل';

  @override
  String get onboarding_activity_lightly => 'نشط قليلاً';

  @override
  String get onboarding_activity_lightly_desc => 'تمرين 1-3 أيام/أسبوع';

  @override
  String get onboarding_activity_moderately => 'نشط باعتدال';

  @override
  String get onboarding_activity_moderately_desc => 'تمرين 3-5 أيام/أسبوع';

  @override
  String get onboarding_activity_active => 'نشط جداً (6-7 أيام)';

  @override
  String get onboarding_activity_active_desc => 'تمرين منتظم خلال الأسبوع';

  @override
  String get onboarding_result_eyebrow => 'خطتك';

  @override
  String get onboarding_result_title => 'هدفك جاهز.';

  @override
  String get onboarding_result_kcal_day => 'سعرة / يوم';

  @override
  String onboarding_result_reach_by(String date) {
    return 'ستصل إلى هدفك بحلول $date';
  }

  @override
  String onboarding_result_pace(String pace, String unit) {
    return 'الوتيرة: $pace $unit / أسبوع';
  }

  @override
  String get onboarding_error_age => 'أدخل عمراً بين 13 و 100.';

  @override
  String get onboarding_error_height =>
      'أدخل طولاً واقعياً لنتمكن من الحساب بدقة.';

  @override
  String get onboarding_error_weight => 'أدخل وزناً حالياً واقعياً.';

  @override
  String get onboarding_error_goal_weight => 'أدخل وزناً مستهدفاً واقعياً.';

  @override
  String get onboarding_error_timeline =>
      'اضبط جدولك الزمني لنتمكن من بناء خطة صالحة.';

  @override
  String get onboarding_error_generic =>
      'لم نتمكن من بناء خطتك. حاول مرة أخرى.';

  @override
  String get onboarding_result_loading_eyebrow => 'نتيجة الذكاء الاصطناعي';

  @override
  String get onboarding_result_loading_title => 'بناء هدف السعرات الخاص بك.';

  @override
  String get onboarding_result_loading_body =>
      'نحن نجمع بين خط الأساس والنشاط ووتيرة الهدف في خطة جاهزة للاستخدام.';

  @override
  String get onboarding_result_calibrating => 'معايرة هدفك اليومي...';

  @override
  String get onboarding_result_error_eyebrow => 'خطأ في الحساب';

  @override
  String get onboarding_result_error_title => 'لم نتمكن من إنهاء خطتك.';

  @override
  String get onboarding_result_error_body =>
      'حاول في الخطوة الأخيرة مرة أخرى أو اضبط مدخلاتك.';

  @override
  String get onboarding_result_success_eyebrow =>
      'اكتملت معايرة الذكاء الاصطناعي';

  @override
  String get onboarding_result_success_title => 'الهدف اليومي جاهز.';

  @override
  String get onboarding_result_success_body =>
      'هذا الرقم مخصص لجسمك ووتيرة هدفك.';

  @override
  String get onboarding_result_minor_warning =>
      'اكتشاف طفيف. يرجى استشارة متخصص قبل البدء في أي تقييد للسعرات الحرارية.';

  @override
  String get onboarding_result_daily_calories => 'السعرات اليومية';

  @override
  String get onboarding_result_strategy => 'الاستراتيجية';

  @override
  String get onboarding_result_recommendation => 'التوصية';

  @override
  String get onboarding_activity_desk_life => 'حياة مكتبية';

  @override
  String get onboarding_activity_desk_life_desc => 'تمرين قليل أو معدوم';

  @override
  String get onboarding_activity_light_mover => 'متحرك خفيف';

  @override
  String get onboarding_activity_light_mover_desc => '1-3 أيام/أسبوع';

  @override
  String get onboarding_activity_active_title => 'نشط بدنياً (3-5 أيام)';

  @override
  String get onboarding_activity_athlete => 'رياضي';

  @override
  String get onboarding_activity_athlete_desc => '6-7 أيام/أسبوع';

  @override
  String get onboarding_activity_footer =>
      'تم اختيار نشط افتراضياً. انقر مرة واحدة وسنستمر في الحركة.';

  @override
  String get onboarding_feature_target => 'هدف السعرات الشخصي';

  @override
  String get onboarding_feature_macros => 'تقسيم الماكرو';

  @override
  String get onboarding_feature_insight => 'رؤية الذكاء الاصطناعي';

  @override
  String get planner_meal => 'وجبة';

  @override
  String get planner_ingredients => 'المكونات';

  @override
  String get common_mins => 'دقيقة';

  @override
  String planner_kcal_total(int goal) {
    return '/ $goal سعرة';
  }

  @override
  String planner_kcal_over(int delta) {
    return '+$delta زائد';
  }

  @override
  String planner_kcal_under(int delta) {
    return '$delta ناقص';
  }

  @override
  String get planner_kcal_on_target => 'على الهدف';

  @override
  String get snap_gallery => 'المعرض';

  @override
  String get snap_barcode => 'باركود';

  @override
  String get snap_pro_unlimited => '∞ برو';

  @override
  String get snap_bento_plate => 'طبق بينتو';

  @override
  String snap_items_detected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اكتشاف $count صنف',
      many: 'تم اكتشاف $count صنفاً',
      few: 'تم اكتشاف $count أصناف',
      two: 'تم اكتشاف صنفين',
      one: 'تم اكتشاف صنف واحد',
      zero: 'لم يتم اكتشاف أصناف',
    );
    return '$_temp0 في طبقك.';
  }

  @override
  String get snap_total_meal => 'إجمالي الوجبة';

  @override
  String snap_items_selected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار $count صنف',
      many: 'تم اختيار $count صنفاً',
      few: 'تم اختيار $count أصناف',
      two: 'تم اختيار صنفين',
      one: 'تم اختيار صنف واحد',
      zero: 'لم يتم اختيار أصناف',
    );
    return '$_temp0';
  }

  @override
  String get settings_body_profile_title => 'الملف البدني';

  @override
  String get settings_body_profile_desc => 'إدارة إحصائياتك وأهدافك البدنية.';

  @override
  String get settings_display_name_label => 'اسم العرض';

  @override
  String get settings_set_name => 'تعيين الاسم';

  @override
  String get settings_current_weight => 'الوزن الحالي';

  @override
  String get settings_set_weight => 'تعيين الوزن';

  @override
  String get settings_height => 'الطول';

  @override
  String get settings_set_height => 'تعيين الطول';

  @override
  String get settings_target_weight => 'الوزن المستهدف';

  @override
  String get settings_set_target => 'تعيين الهدف';

  @override
  String get settings_nutrition_goals_title => 'أهداف التغذية';

  @override
  String get settings_daily_calories => 'السعرات اليومية';

  @override
  String get settings_protein => 'بروتين';

  @override
  String get settings_carbs => 'كربوهيدرات';

  @override
  String get settings_fat => 'دهون';

  @override
  String get settings_optimize_btn => 'تحسين خطة التغذية';

  @override
  String get settings_optimizing => 'جاري التحسين...';

  @override
  String get settings_recalculate_query =>
      'لقد قمت للتو بتحسين خطة التغذية الخاصة بي. يرجى شرح لماذا تم اختيار هذه السعرات والماكرو المحددة لي بناءً على ملفي الشخصي.';

  @override
  String get settings_guest_account => 'حساب ضيف';

  @override
  String get settings_sign_in => 'تسجيل الدخول';

  @override
  String get settings_member => 'عضو سناب كال';

  @override
  String get settings_auth_cta => 'سجل أو ادخل';

  @override
  String get settings_preferences_title => 'التفضيلات';

  @override
  String get settings_notifications => 'التنبيهات';

  @override
  String get settings_meal_reminders => 'تذكير الوجبات';

  @override
  String get settings_daily_motivation => 'تحفيز يومي';

  @override
  String get settings_language => 'اللغة';

  @override
  String get settings_account_title => 'الحساب';

  @override
  String get settings_subscription => 'الاشتراك';

  @override
  String get settings_pro_active => 'برو نشط';

  @override
  String get settings_manage_plan => 'إدارة الخطة';

  @override
  String get settings_create_account => 'إنشاء حساب';

  @override
  String get settings_sign_out_desc => 'مغادرة جلسة الجهاز هذه';

  @override
  String get settings_sync_data_desc => 'مزامنة بياناتك';

  @override
  String get settings_about_app => 'حول سناب كال';

  @override
  String get settings_legalese => '© 2026 سناب كال. جميع الحقوق محفوظة.';

  @override
  String get onboarding_result_maintain => 'الحفاظ على الوزن الحالي';

  @override
  String onboarding_result_weekly_rate(String rate) {
    return '~$rate كجم / أسبوع';
  }

  @override
  String get error_connection_title => 'مشكلة في الاتصال';

  @override
  String get error_connection_body =>
      'تعذر تهيئة SnapCal. يرجى التحقق من البيانات أو شبكة Wi-Fi.';

  @override
  String get error_unexpected_title => 'حدث خطأ ما';

  @override
  String get error_unexpected_body =>
      'واجهنا خطأ غير متوقع. تم إخطار فريقنا ونحن نعمل على إصلاحه.';

  @override
  String get report_guest_user => 'مستخدم عزيز';

  @override
  String get report_avg_calories => 'متوسط السعرات';

  @override
  String get report_consistency => 'الالتزام';

  @override
  String get report_calorie_trend => 'اتجاه السعرات';

  @override
  String get report_macro_dist => 'توزيع العناصر';

  @override
  String get report_macro_protein => 'بروتين';

  @override
  String get report_macro_carbs => 'كربوهيدرات';

  @override
  String get report_macro_fat => 'دهون';

  @override
  String get report_no_weight_title => 'لا توجد سجلات وزن بعد';

  @override
  String get report_no_weight_body =>
      'أضف أول سجل لك ليبدأ اتجاه جسمك في الظهور.';

  @override
  String get report_log_weight => 'سجل الوزن';

  @override
  String get report_weight_current => 'الحالي';

  @override
  String get report_weight_change => 'التغيير';

  @override
  String get report_progress_timeline => 'الجدول الزمني للتقدم';

  @override
  String get report_progress_gallery => 'معرض تحول الجسم البصري';

  @override
  String get report_weight_analytics => 'تحليلات الوزن';

  @override
  String get report_recent_history => 'السجل الأخير';

  @override
  String report_body_fat_pct(String percent) {
    return '$percent٪ دهون';
  }

  @override
  String get weight_hint => 'الوزن';

  @override
  String get body_fat_hint => 'دهون الجسم (اختياري)';

  @override
  String get snap_scan_barcode => 'مسح الباركود';

  @override
  String get snap_barcode_hint => 'ضع الباركود داخل الإطار.';

  @override
  String get snap_torch => 'كشاف';

  @override
  String get snap_flip => 'قلب الكاميرا';

  @override
  String get settings_health_sync => 'مزامنة الصحة';

  @override
  String get settings_health_sync_sub =>
      'مزامنة الخطوات والسعرات الحرارية المحروقة';

  @override
  String get home_metric_activity => 'النشاط';

  @override
  String get home_metric_activity_sync => 'مزامنة';

  @override
  String get home_metric_activity_enable => 'تفعيل الصحة';

  @override
  String get progress_generate_video => 'إنشاء فيديو الرحلة';

  @override
  String get progress_video_failed => 'فشل إنشاء الفيديو. حاول مرة أخرى.';

  @override
  String get progress_video_min_photos =>
      'التقط صورتين للتقدم على الأقل أولاً!';

  @override
  String get progress_video_share_text => 'رحلة تحول SnapCal الخاصة بي! 🚀';

  @override
  String get widget_status_on_track => 'على المسار الصحيح';

  @override
  String get widget_status_over_goal => 'فوق الهدف';

  @override
  String get widget_status_almost_there => 'على وشك الوصول';

  @override
  String get feature_insights_title => 'ملخص الأسبوع';

  @override
  String get feature_insights_desc => 'مراجعة أسبوعك';

  @override
  String feature_insights_avg_cal(String cal) {
    return 'متوسط $cal سعرة/يوم';
  }

  @override
  String feature_insights_on_track(String days) {
    return '$days أيام على المسار';
  }

  @override
  String get feature_insights_generating => 'جاري توليد الرؤى...';

  @override
  String get feature_insights_share => 'شارك أسبوعي';

  @override
  String get feature_templates_title => 'روتينياتي';

  @override
  String get feature_templates_empty =>
      'احفظ روتينك الأول! سجل وجبة، ثم اضغط على \'حفظ كروتين\'.';

  @override
  String get feature_templates_save_prompt => 'حفظ كروتين؟';

  @override
  String get feature_templates_name_hint => 'مثال: فطور الصباح';

  @override
  String get feature_templates_save_btn => 'حفظ الروتين';

  @override
  String get feature_templates_update_btn => 'تحديث الروتين';

  @override
  String get feature_templates_limit_reached =>
      'تم الوصول للحد المجاني. قم بالترقية لروتينات لا محدودة!';

  @override
  String get feature_templates_logged => 'تم تسجيل الروتين بنجاح!';

  @override
  String get feature_achievements_title => 'الإنجازات';

  @override
  String feature_achievements_unlocked(String count) {
    return 'تم فتح $count';
  }

  @override
  String get achievement_first_flame => 'الشعلة الأولى';

  @override
  String get achievement_first_flame_desc => 'سجل وجبتك الأولى';

  @override
  String get achievement_consistency_king => 'ملك الاستمرارية';

  @override
  String get achievement_consistency_king_desc => 'سلسلة من 7 أيام';

  @override
  String get achievement_iron_will => 'إرادة حديدية';

  @override
  String get achievement_iron_will_desc => 'سلسلة من 30 يوماً';

  @override
  String get achievement_unstoppable => 'لا يمكن إيقافه';

  @override
  String get achievement_unstoppable_desc => 'سلسلة من 100 يوم';

  @override
  String get achievement_bullseye => 'في الهدف';

  @override
  String get achievement_bullseye_desc => 'حقق هدف السعرات بالضبط';

  @override
  String get achievement_precision_pro => 'محترف الدقة';

  @override
  String get achievement_precision_pro_desc => 'حقق هدف السعرات لـ 7 أيام';

  @override
  String get achievement_macro_master => 'سيد الماكرو';

  @override
  String get achievement_macro_master_desc => 'حقق جميع الماكرو في يوم';

  @override
  String get achievement_perfect_week => 'أسبوع مثالي';

  @override
  String get achievement_perfect_week_desc => 'حقق كل الأهداف لـ 7 أيام';

  @override
  String get achievement_first_sip => 'الرشفة الأولى';

  @override
  String get achievement_first_sip_desc => 'سجل الماء لأول مرة';

  @override
  String get achievement_hydration_hero => 'بطل الترطيب';

  @override
  String get achievement_hydration_hero_desc => 'هدف الماء لـ 30 يوماً';

  @override
  String get achievement_ocean_mode => 'وضع المحيط';

  @override
  String get achievement_ocean_mode_desc => 'هدف الماء لـ 100 يوم';

  @override
  String get achievement_first_snap => 'اللقطة الأولى';

  @override
  String get achievement_first_snap_desc => 'سجل وجبة واحدة بالكاميرا';

  @override
  String get achievement_snap_master => 'سيد اللقطات';

  @override
  String get achievement_snap_master_desc => 'سجل 100 وجبة';

  @override
  String get achievement_snap_legend => 'أسطورة اللقطات';

  @override
  String get achievement_snap_legend_desc => 'سجل 500 وجبة';

  @override
  String get achievement_first_checkin => 'الفحص الأول';

  @override
  String get achievement_first_checkin_desc => 'سجل أول صورة للجسم';

  @override
  String get achievement_transformation => 'التحول';

  @override
  String get achievement_transformation_desc => 'سجل 10 صور للجسم';

  @override
  String get achievement_journey_video => 'فيديو الرحلة';

  @override
  String get achievement_journey_video_desc => 'توليد فيديو التحول';

  @override
  String get feature_achievements_unlocked_title => 'تم فتح إنجاز!';

  @override
  String get common_continue => 'استمرار';

  @override
  String get feature_insights_subtitle =>
      'ملخصك الأسبوعي للتغذية بالذكاء الاصطناعي جاهز!';

  @override
  String get feature_insights_share_text =>
      'اطلع على ملخصي الأسبوعي للتغذية من سناب كال! 📊';

  @override
  String get settings_guest_title => 'احمِ تقدمك';

  @override
  String get settings_guest_subtitle => 'سجل الدخول لمزامنة بياناتك بأمان.';

  @override
  String get activity_tracking_status => 'حالة التتبع';

  @override
  String get activity_active => 'نشط';

  @override
  String get activity_description =>
      'أجهزة الاستشعار في هاتفك تتبع خطواتك بنشاط لحرق السعرات الحرارية اليوم.';

  @override
  String get activity_authorize_desc =>
      'لتتبع خطواتك تلقائيًا، يرجى السماح بالتعرف على النشاط.';

  @override
  String get activity_authorize_btn => 'السماح بالتتبع';

  @override
  String get activity_motivation_low => 'كل خطوة مهمة. دعنا نتحرك اليوم!';

  @override
  String get activity_motivation_mid =>
      'أنت في طريقك! المشي السريع قد يساعدك في الوصول إلى هدفك.';

  @override
  String get activity_motivation_high =>
      'اقتربت من الوصول! أنت تحقق أهداف نشاطك.';

  @override
  String get activity_motivation_elite =>
      'رائع! أنت في منطقة النشاط النخبة اليوم.';

  @override
  String get home_scan_food => 'مسح الطعام';

  @override
  String get home_go_pro => 'كن برو';

  @override
  String get home_pro_badge => 'برو';

  @override
  String get settings_upgrade_to_pro => 'الترقية إلى برو';

  @override
  String get settings_emerald_badge => 'زمرد';

  @override
  String get coach_limit_title => 'تم الوصول إلى الحد اليومي';

  @override
  String get coach_limit_subtitle =>
      'اشترك في النسخة المميزة للحصول على توجيه غير محدود وإرشاد ذكي للوجبات مصمم خصيصاً لأهدافك.';

  @override
  String get coach_limit_btn => 'الترقية لمحادثة غير محدودة';

  @override
  String get coach_see_options => 'عرض خيارات الاشتراك';

  @override
  String get coach_locked_title => 'اعرف ماذا تأكل بعد ذلك.';

  @override
  String get coach_locked_desc =>
      'يقرأ مدرب الذكاء الاصطناعي سعراتك الحرارية وعناصرك الغذائية وهدفك اليوم، ثم يقدم نصائح غذائية واضحة.';

  @override
  String get coach_preview_meal_title => 'اقتراح الوجبة التالية';

  @override
  String get coach_preview_meal_body =>
      'أفضل وجبة تالية: وعاء أرز الدجاج المشوي، حوالي 550 سعرة حرارية.';

  @override
  String get coach_preview_macro_title => 'تصحيح العناصر الغذائية';

  @override
  String get coach_preview_macro_body =>
      'ما زلت بحاجة إلى 45 جرام من البروتين و 120 جرام من الكربوهيدرات اليوم.';

  @override
  String get coach_preview_feedback_title => 'ملاحظات التقدم اليومي';

  @override
  String get coach_preview_feedback_body =>
      'نسبة البروتين لديك منخفضة. أضف البيض، التونة، أو الزبادي اليوناني بعد ذلك.';

  @override
  String get report_prompt_title => 'تقريرك الأسبوعي جاهز';

  @override
  String get report_prompt_subtitle =>
      'افتح نظرة أعمق لمعرفة سبب تجاوز الأهداف في بعض الأيام وكيفية التحسين في الأسبوع المقبل.';

  @override
  String get report_prompt_btn => 'فتح التقرير الأسبوعي';

  @override
  String get scan_overlay_scanning => 'مسح رؤية الذكاء الاصطناعي';

  @override
  String get scan_overlay_desc =>
      'الكشف عن المكونات وحساب الكثافة الغذائية باستخدام Gemini...';

  @override
  String get scan_overlay_manual => 'تسجيل يدوياً';

  @override
  String get report_card_title => 'تقرير التقدم الأسبوعي';

  @override
  String get report_card_subtitle =>
      'تعرف على سبب تجاوز الأهداف في بعض الأيام واحصل على اقتراحات مخصصة لتصحيح ذلك.';

  @override
  String get startup_launch_issue => 'حدثت مشكلة أثناء التشغيل';

  @override
  String get startup_initialization_slow =>
      'يستغرق التهيئة وقتاً أطول من المتوقع.';

  @override
  String get startup_setup_failed =>
      'حدث خطأ أثناء إعداد التطبيق. يرجى المحاولة مرة أخرى.';

  @override
  String get startup_retry_launch => 'إعادة محاولة التشغيل';

  @override
  String get startup_initialization_error => 'خطأ في التهيئة';

  @override
  String get startup_error_body =>
      'واجه التطبيق خطأ عند بدء التشغيل. يرجى محاولة إعادة التشغيل.';

  @override
  String get startup_reload => 'إعادة تحميل';

  @override
  String get activity_live_tracking => 'تتبع مباشر';

  @override
  String get activity_stationary => 'ثابت';

  @override
  String get activity_steps_today_label => 'خطوات اليوم';

  @override
  String get activity_calories_label => 'السعرات';

  @override
  String get activity_goal_label => 'الهدف';

  @override
  String get activity_tracking_engine => 'محرك التتبع';

  @override
  String get activity_active_encrypted => 'نشط ومشفر';

  @override
  String get activity_permission_required => 'الإذن مطلوب';

  @override
  String get activity_steps_synced => 'تتم مزامنة خطواتك في الوقت الفعلي.';

  @override
  String get activity_enable_tracking => 'فعّل التتبع لرؤية تقدمك.';

  @override
  String feature_insights_share_error(String error) {
    return 'خطأ أثناء المشاركة: $error';
  }

  @override
  String get feature_insights_empty => 'لا توجد بيانات لهذا الأسبوع بعد.';

  @override
  String get feature_insights_calorie_trend => 'اتجاه السعرات';

  @override
  String get feature_insights_ai_coach => 'رؤى مدرب الذكاء الاصطناعي';

  @override
  String get auth_intro_body => 'تبدأ رحلتك نحو صحة أفضل من هنا.';

  @override
  String get auth_back_to_social => 'العودة إلى تسجيل الدخول الاجتماعي';

  @override
  String get auth_create_account => 'إنشاء حساب';

  @override
  String get auth_welcome_back_title => 'مرحباً بعودتك';

  @override
  String get home_welcome_guest => 'مرحباً بك في SnapCal';

  @override
  String get auth_lets_dive => 'لنبدأ';

  @override
  String get auth_sign_up_short => 'تسجيل';

  @override
  String get auth_log_in => 'دخول';

  @override
  String get auth_have_account => 'لديك حساب بالفعل؟ ';

  @override
  String get auth_no_account => 'ليس لديك حساب؟ ';

  @override
  String get common_or => 'أو';

  @override
  String get common_today => 'اليوم';

  @override
  String get common_yesterday => 'أمس';

  @override
  String get common_tomorrow => 'غداً';

  @override
  String get common_maybe_later => 'ربما لاحقاً';

  @override
  String get settings_category_body_profile_sub =>
      'قياسات الجسم والوحدات والوزن المستهدف';

  @override
  String get settings_category_nutrition_sub =>
      'أهداف السعرات والبروتين والكربوهيدرات والدهون';

  @override
  String get settings_category_preferences_sub =>
      'المظهر واللغة والتذكيرات وتخطيط الوجبات';

  @override
  String get settings_category_achievements_sub =>
      'السلاسل والإنجازات ومكافآت التقدم';

  @override
  String get settings_category_account_sub =>
      'تسجيل الدخول واسم الملف الشخصي والتحكم بالحساب';

  @override
  String get settings_category_data_sync_sub =>
      'النسخ الاحتياطي والاستعادة وبيانات التطبيق المحلية';

  @override
  String get settings_category_about_sub =>
      'الإصدار والخصوصية والشروط ومعلومات التطبيق';

  @override
  String get home_go_deeper_title => 'تعمق أكثر';

  @override
  String get home_go_deeper_body =>
      'مراجعات يومية بالذكاء الاصطناعي، واتجاهات العناصر، والسجل الكامل.';

  @override
  String get home_daily_wellness => 'العافية اليومية';

  @override
  String get home_add => 'إضافة';

  @override
  String get home_daily_score => 'النتيجة اليومية';

  @override
  String get log_monthly_calendar_soon => 'التقويم الشهري قريباً';

  @override
  String get log_today_subtitle => 'تتبع ما تأكله اليوم';

  @override
  String get log_review_day => 'راجع هذا اليوم';

  @override
  String get log_scan_food => 'مسح الطعام';

  @override
  String get feature_templates_saved_meals => 'الوجبات المحفوظة';

  @override
  String get feature_templates_saved_added => 'تمت إضافة الوجبة المحفوظة';

  @override
  String get feature_templates_deleted => 'تم حذف الروتين';

  @override
  String get premium_analysis_title => 'تحليل مميز';

  @override
  String get premium_analysis_body =>
      'احصل على نسخة أفضل من هذه الوجبة حسب هدفك مع اقتراحات الذكاء الاصطناعي.';

  @override
  String get result_meal_name => 'اسم الوجبة';

  @override
  String get result_feast => 'وليمة';

  @override
  String get result_ai_meal_insight => 'رؤية الوجبة بالذكاء الاصطناعي';

  @override
  String get result_ai_meal_body => 'وازن هذه الوجبة باقتراح ذكي واحد.';

  @override
  String get result_add_new_item => 'إضافة عنصر جديد';

  @override
  String get result_total_calories => 'إجمالي السعرات';

  @override
  String get result_food_details => 'تفاصيل الطعام';

  @override
  String get result_food => 'الطعام';

  @override
  String get result_portion_label => 'الحصة';

  @override
  String get result_add_item => 'إضافة عنصر';

  @override
  String get result_nutrition_details => 'تفاصيل التغذية';

  @override
  String get result_unlock_nutrition => 'فتح تفاصيل التغذية';

  @override
  String get result_add_to_log => 'إضافة إلى السجل';

  @override
  String get paywall_cancel_anytime => 'يمكنك الإلغاء في أي وقت. بلا التزام.';

  @override
  String get paywall_terms_conditions => 'الشروط والأحكام';

  @override
  String get paywall_trial_7_day => 'تجربة 7 أيام';

  @override
  String get paywall_scan_limit_subtitle =>
      'استخدمت 3 من 3 عمليات مسح مجانية اليوم. افتح مسح طعام غير محدود بالذكاء الاصطناعي وتحليل السعرات فوراً.';

  @override
  String get paywall_coach_subtitle =>
      'افتح تدريباً غير محدود وإرشاداً للعناصر الغذائية واقتراحات وجبات مناسبة ليومك.';

  @override
  String get paywall_planner_subtitle =>
      'افتح خططاً أسبوعية كاملة وقوائم مشتريات وتفضيلات وإعادة توليد وجبات بالذكاء الاصطناعي.';

  @override
  String paywall_reports_subtitle(String feature) {
    return 'افتح تحليلاً أعمق واتجاهات أسبوعية واقتراحات عملية بالذكاء الاصطناعي بعد كل $feature.';
  }

  @override
  String get paywall_progress_subtitle =>
      'افتح المزيد من صور التقدم والمقارنات وتتبع التحول بعد الحد الشهري المجاني.';

  @override
  String get paywall_ad_removal_subtitle =>
      'اشترك في Pro لإزالة الإعلانات وفتح تجربة التغذية الكاملة بالذكاء الاصطناعي.';

  @override
  String get progress_weight_trend => 'اتجاه الوزن';

  @override
  String get progress_log_custom_weight => 'اضغط لتسجيل وزنك المخصص';

  @override
  String get log_calories_eaten => 'السعرات المستهلكة';

  @override
  String log_kcal_over(int amount) {
    return '$amount فوق الهدف';
  }

  @override
  String log_kcal_left(int amount) {
    return '$amount متبقية';
  }

  @override
  String get log_no_details => 'لم يتم تسجيل تفاصيل لهذا اليوم بعد.';

  @override
  String log_over_target_insight(int amount) {
    return 'سجلت $amount سعرة فوق الهدف. راجع الوجبات الأثقل أدناه.';
  }

  @override
  String log_low_protein_insight(int calories) {
    return 'سجلت $calories سعرة وكان البروتين أقل من الهدف.';
  }

  @override
  String log_water_behind_insight(int calories) {
    return 'سجلت $calories سعرة. لا يزال شرب الماء أقل من الهدف اليوم.';
  }

  @override
  String log_balanced_day_insight(int calories) {
    return 'سجلت $calories سعرة مع يوم متوازن حتى الآن.';
  }

  @override
  String feature_templates_save_desc(int count) {
    return 'احفظ هذه العناصر الـ $count للتسجيل لاحقاً بلمسة واحدة.';
  }

  @override
  String get achievement_category_consistency => 'الاستمرارية';

  @override
  String get achievement_category_precision => 'الدقة';

  @override
  String get achievement_category_hydration => 'الترطيب';

  @override
  String get achievement_category_logging => 'التسجيل';

  @override
  String get achievement_category_progress => 'التقدم';

  @override
  String get achievement_unlocked_label => 'مفتوح';

  @override
  String get report_pdf_title => 'تقرير التغذية بالذكاء الاصطناعي';

  @override
  String report_pdf_user(String name) {
    return 'المستخدم: $name';
  }

  @override
  String get report_pdf_weekly_performance => 'الأداء الأسبوعي';

  @override
  String get report_pdf_total_protein => 'إجمالي البروتين';

  @override
  String get report_pdf_active_streak => 'سلسلة النشاط';

  @override
  String get report_pdf_grams => 'جرام';

  @override
  String get report_pdf_days => 'أيام';

  @override
  String get report_pdf_macro_distribution => 'توزيع العناصر الغذائية';

  @override
  String get report_pdf_nutrient => 'العنصر';

  @override
  String get report_pdf_total_consumed => 'الإجمالي المستهلك';

  @override
  String get report_pdf_daily_target => 'الهدف اليومي';

  @override
  String get report_pdf_goal_status => 'حالة الهدف';

  @override
  String get report_pdf_carbohydrates => 'الكربوهيدرات';

  @override
  String get report_pdf_fats => 'الدهون';

  @override
  String get report_pdf_meal_log => 'سجل الوجبات التفصيلي (آخر 7 أيام)';

  @override
  String get report_pdf_date => 'التاريخ';

  @override
  String get report_pdf_meal_item => 'الوجبة';

  @override
  String get report_pdf_type => 'النوع';

  @override
  String get report_pdf_footer =>
      'تم إنشاء هذا التقرير تلقائياً بواسطة SnapCal AI.';

  @override
  String get report_pdf_tagline => 'استمر بثبات، وابقَ صحياً.';

  @override
  String get onboarding_safety_safer_pace => 'سنقترح وتيرة أكثر أماناً.';

  @override
  String get onboarding_safety_surplus_capped =>
      'حددنا فائض السعرات لإبقاء الخطة واقعية.';

  @override
  String get onboarding_safety_floor =>
      'أبقينا هدفك فوق الحد الأدنى الآمن للسعرات.';

  @override
  String onboarding_safety_floor_extra(String note) {
    return '$note تم تطبيق الحد الأدنى الآمن للسعرات.';
  }

  @override
  String onboarding_insight_desk(int calories) {
    return '$calories سعرة تجعل خطتك واقعية مع نمط نشاط منخفض.';
  }

  @override
  String onboarding_insight_light(int calories) {
    return '$calories سعرة تمنحك هدفاً ثابتاً يناسب حركة أسبوعية خفيفة.';
  }

  @override
  String onboarding_insight_athlete(int calories) {
    return '$calories سعرة تدعم احتياج التدريب دون تسريع الوتيرة كثيراً.';
  }

  @override
  String onboarding_insight_default(int calories) {
    return '$calories سعرة توازن بين هدفك وحجم جسمك ومستوى نشاطك الحالي.';
  }

  @override
  String get onboarding_tip_desk =>
      'المشي 20 دقيقة بعد الوجبات طريقة سهلة لتحسين الالتزام.';

  @override
  String get onboarding_tip_light =>
      'جلستا حركة إضافيتان أسبوعياً ستجعلان هذا الهدف أسهل للاستمرار.';

  @override
  String get onboarding_tip_athlete =>
      'وزع البروتين على كل وجبة لدعم التعافي والسيطرة على الشهية.';

  @override
  String get onboarding_tip_bulk =>
      'اجعل معظم السعرات الإضافية حول التدريب لتحسين الأداء.';

  @override
  String get onboarding_tip_default =>
      'ابنِ وجباتك حول البروتين أولاً حتى يصبح الهدف أسهل.';

  @override
  String get paywall_slide_grilled_chicken => 'دجاج مشوي';

  @override
  String get paywall_slide_rice => 'أرز';

  @override
  String get paywall_slide_avocado => 'أفوكادو';

  @override
  String get paywall_slide_toast => 'توست';

  @override
  String get paywall_slide_cherry_tomatoes => 'طماطم كرزية';

  @override
  String get paywall_slide_salmon => 'فيليه سلمون';

  @override
  String get paywall_slide_sweet_potato => 'بطاطا حلوة';

  @override
  String get paywall_slide_broccoli => 'بروكلي';

  @override
  String get paywall_slide_boiled_eggs => 'بيض مسلوق';

  @override
  String get paywall_slide_chicken_portion => '١٥٠ جم';

  @override
  String get paywall_slide_rice_portion => '١٣٠ جم';

  @override
  String get paywall_slide_avocado_portion => '١٠٠ جم';

  @override
  String get paywall_slide_tomatoes_portion => '٨٠ جم';

  @override
  String get paywall_slide_salmon_portion => '١٥٠ جم';

  @override
  String get paywall_slide_sweet_potato_portion => '١٣٠ جم';

  @override
  String get paywall_slide_broccoli_portion => '١٠٠ جم';

  @override
  String get paywall_slide_eggs_portion => 'بيضتان';

  @override
  String get paywall_slide_toast_portion => 'شريحتان';

  @override
  String get scan_step_uploading => 'جاري رفع صورة الطعام...';

  @override
  String get scan_step_scanning => 'جاري فحص الأشكال البصرية...';

  @override
  String get scan_step_ingredients => 'جاري تحديد المكونات...';

  @override
  String get scan_step_portions => 'جاري تقدير حجم الحصص...';

  @override
  String get scan_step_calories => 'جاري حساب كثافة السعرات الحرارية...';

  @override
  String get scan_step_macros => 'جاري موازنة العناصر الغذائية...';

  @override
  String get scan_step_finalizing => 'جاري إنهاء بطاقة التغذية...';

  @override
  String get common_camera => 'الكاميرا';

  @override
  String get assistant_quick_macros => 'تعديل الماكروز الخاصة بي';

  @override
  String get assistant_quick_next_meal => 'ماذا يجب أن آكل بعد ذلك؟';

  @override
  String get assistant_quick_snack => 'وجبة خفيفة عالية البروتين';

  @override
  String assistant_meals_logged_today(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بناءً على $count وجبة مسجلة اليوم',
      one: 'بناءً على وجبة واحدة مسجلة اليوم',
      zero: 'لم يتم تسجيل وجبات اليوم',
    );
    return '$_temp0';
  }

  @override
  String get assistant_ask_coach_header => 'اسأل مدربك';

  @override
  String get assistant_brief_today => 'ملخص المدرب لليوم';

  @override
  String get assistant_live => 'مباشر';

  @override
  String get assistant_brief_left => 'المتبقي';

  @override
  String get assistant_protein_gap => 'فجوة البروتين';

  @override
  String get assistant_to_goal => 'للوصول للهدف';

  @override
  String get assistant_last_meal => 'آخر وجبة';

  @override
  String get assistant_next_move => 'الخطوة التالية';

  @override
  String get assistant_no_meals_logged => 'لم يتم تسجيل وجبات بعد';

  @override
  String get assistant_action_log_meal => 'سجل وجبة للحصول على توجيه دقيق';

  @override
  String get assistant_action_protein =>
      'أعطِ الأولوية للبروتين في وجبتك القادمة';

  @override
  String get assistant_action_light => 'اجعل خيارك القادم خفيفًا';

  @override
  String get assistant_action_balanced => 'حافظ على توازن وجبتك القادمة';

  @override
  String get assistant_analyze_image_prompt => 'حلل هذه الصورة.';

  @override
  String common_items_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر',
      one: 'عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get settings_weight_loss_progress => 'تقدم خسارة الوزن';

  @override
  String get settings_weight_gain_progress => 'تقدم زيادة الوزن';

  @override
  String get settings_weight_start => 'البداية';

  @override
  String get settings_weight_current => 'الحالي';

  @override
  String get settings_weight_target => 'الهدف';

  @override
  String get settings_goal_reached => 'تم تحقيق الهدف! 🎉';

  @override
  String settings_left_to_reach_target(String amount, String unit) {
    return 'متبقي $amount $unit للوصول للهدف';
  }

  @override
  String get settings_macro_calorie_split => 'تقسيم سعرات العناصر الغذائية';

  @override
  String get settings_macro_calorie_split_desc =>
      'نسبة السعرات الحرارية الإجمالية التي يساهم بها كل عنصر';

  @override
  String get settings_step_tracking => 'تتبع الخطوات';

  @override
  String get settings_syncing_activity => 'جاري مزامنة بيانات النشاط...';

  @override
  String get settings_sync_now => 'مزامنة الآن';

  @override
  String get settings_sync_now_desc =>
      'تحديث الخطوات والسعرات الحرارية المقدرة';

  @override
  String settings_last_synced(String time) {
    return 'آخر مزامنة $time';
  }

  @override
  String get settings_disconnect_steps => 'إيقاف تتبع الخطوات';

  @override
  String get settings_disconnect_steps_desc =>
      'إيقاف الاستماع لتحديثات خطوات الهاتف';

  @override
  String get settings_status_enabled => 'التتبع مفعّل';

  @override
  String get settings_status_denied => 'تم رفض الإذن';

  @override
  String get settings_status_unsupported => 'الجهاز غير مدعوم';

  @override
  String get settings_status_error => 'خطأ في التتبع';

  @override
  String get settings_status_off => 'التتبع متوقف';

  @override
  String get settings_gender_male => 'ذكر';

  @override
  String get settings_gender_female => 'أنثى';

  @override
  String get settings_gender_other => 'آخر';

  @override
  String get settings_age_unit => 'سنة';

  @override
  String get settings_kcal_unit => 'سعرة حرارية';

  @override
  String get settings_grams_unit => 'جم';

  @override
  String get settings_unit_kg => 'كجم';

  @override
  String get settings_unit_lb => 'رطل';

  @override
  String get settings_unit_cm => 'سم';

  @override
  String get settings_unit_in => 'بوصة';

  @override
  String get paywall_unlock_snapcal_pro => 'افتح SnapCal Pro';

  @override
  String get paywall_barcode_title => 'افتح ماسح الباركود';

  @override
  String get paywall_barcode_subtitle =>
      'سجّل الأطعمة المعلبة فورًا عبر مسح الباركود';

  @override
  String get paywall_free_scans_used_title =>
      'استخدمت 3/3 من الفحوصات المجانية اليوم';

  @override
  String get paywall_unlimited_scanning_subtitle =>
      'قم بالترقية لفتح المسح غير المحدود';

  @override
  String get paywall_unlimited_scanning_title => 'افتح المسح غير المحدود';

  @override
  String get paywall_scan_track_subtitle =>
      'قم بالترقية لمسح كل وجباتك وتتبعها';

  @override
  String get paywall_ai_coaching_title =>
      'افتح تدريب الذكاء الاصطناعي غير المحدود';

  @override
  String get paywall_ai_coaching_subtitle => 'إرشاد تغذوي شخصي على مدار الساعة';

  @override
  String get paywall_smart_planning_title => 'افتح تخطيط الوجبات الذكي';

  @override
  String get paywall_smart_planning_subtitle => 'خطط يومية مخصصة لأهدافك';

  @override
  String get paywall_shopping_lists_title => 'قوائم تسوق يتم إنشاؤها تلقائيًا';

  @override
  String get paywall_shopping_lists_subtitle =>
      'وفّر الوقت مع تجميع ذكي للمشتريات';

  @override
  String get paywall_progress_journey_title => 'رحلة تقدم مرئية';

  @override
  String get paywall_progress_journey_subtitle => 'تتبع صور تحول جسمك';

  @override
  String get paywall_analytics_title => 'تحليلات أيضية متقدمة';

  @override
  String get paywall_analytics_subtitle => 'افتح اتجاهات تغذية مخصصة';

  @override
  String get paywall_focused_title => 'تجربة مركزة 100%';

  @override
  String get paywall_focused_subtitle => 'أزل كل الإعلانات والمقاطعات';

  @override
  String get paywall_upgrade_experience_title => 'طوّر تجربتك';

  @override
  String get paywall_upgrade_experience_subtitle =>
      'افتح كل ميزات الاشتراك اليوم';

  @override
  String get paywall_benefit_unlimited_scans => 'مسح غير محدود';

  @override
  String get paywall_benefit_ai_guidance => 'إرشاد بالذكاء الاصطناعي';

  @override
  String get paywall_benefit_full_history => 'السجل الكامل';

  @override
  String get paywall_benefit_weekly_reports => 'تقارير أسبوعية';

  @override
  String get paywall_benefit_ad_free => 'بدون إعلانات';

  @override
  String get paywall_benefit_smart_planner => 'مخطط ذكي';

  @override
  String paywall_price_target(String price) {
    return 'السعر المستهدف $price';
  }

  @override
  String get paywall_billing_monthly => 'فاتورة شهرية';

  @override
  String get paywall_billing_lifetime => 'دفع لمرة واحدة';

  @override
  String get assistant_action_fix_macros => 'اضبط الماكروز اليوم';

  @override
  String get assistant_action_plan_next_meal => 'خطط وجبتي التالية';

  @override
  String get assistant_action_light_dinner => 'اقترح عشاءً خفيفًا';

  @override
  String assistant_coaching_with_meals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تدريب مع $count وجبات مسجلة اليوم',
      one: 'تدريب مع وجبة واحدة مسجلة اليوم',
      zero: 'تدريب بدون وجبات مسجلة اليوم',
    );
    return '$_temp0';
  }

  @override
  String get assistant_start_new_chat => 'ابدأ محادثة جديدة';

  @override
  String get assistant_new_chat => 'محادثة جديدة';

  @override
  String get assistant_coach_insight => 'رؤية المدرب';

  @override
  String get assistant_recipe_estimated_macros => 'خطة وصفة مع ماكروز تقديرية';

  @override
  String get assistant_personalized_from_today => 'مخصص حسب تغذيتك اليوم';

  @override
  String get assistant_step_recipe_plan => 'خطة وصفة خطوة بخطوة';

  @override
  String get assistant_recipe => 'وصفة';

  @override
  String get assistant_ingredients => 'المكونات';

  @override
  String get assistant_what_to_do => 'ما الذي تفعله';

  @override
  String get assistant_recipe_plan => 'خطة وصفة';

  @override
  String get assistant_plan_meal => 'خطط وجبة';

  @override
  String get assistant_adjust_macros => 'عدّل الماكروز';

  @override
  String get assistant_ask_follow_up => 'اسأل متابعة';

  @override
  String activity_steps_goal(int steps) {
    return 'الهدف: $steps خطوة';
  }

  @override
  String get activity_unlock_pro_title => 'افتح ميزات النشاط الاحترافية';

  @override
  String get activity_unlock_pro_subtitle =>
      'قم بالترقية لفتح تعديل هدف السعرات من الخطوات، والسلاسل الأسبوعية، وسعرات التمارين اليدوية، ودرجة النشاط، والرؤى.';

  @override
  String get activity_manual_workouts => 'تمارين يدوية';

  @override
  String get activity_no_manual_workouts => 'لا توجد تمارين يدوية مسجلة اليوم.';

  @override
  String get activity_default_workout => 'تمرين';

  @override
  String get activity_add_workout => 'إضافة تمرين';

  @override
  String get activity_workout_type => 'نوع التمرين';

  @override
  String get activity_minutes => 'الدقائق';

  @override
  String get activity_save_workout => 'حفظ التمرين';

  @override
  String activity_insight_goal_met(int steps) {
    return 'بلغ متوسط خطواتك $steps خطوة هذا الأسبوع وأنت تحقق هدف الخطوات.';
  }

  @override
  String activity_insight_goal_gap(int steps) {
    return 'بلغ متوسط خطواتك $steps خطوة هذا الأسبوع. يمكن لمشي قصير أن يساعدك على سد الفجوة.';
  }

  @override
  String common_minutes_short(int minutes) {
    return '$minutes د';
  }

  @override
  String common_kcal_value(int calories) {
    return '$calories سعرة';
  }

  @override
  String get splash_status_initializing => 'تهيئة محرك ذكاء السعرات...';

  @override
  String get splash_status_database => 'فتح قاعدة البيانات المشفرة...';

  @override
  String get splash_status_ai_gateways =>
      'إعداد مدرب الذكاء الاصطناعي وبوابات Gemini...';

  @override
  String get splash_status_dashboard => 'معايرة لوحة العافية...';

  @override
  String get splash_status_sync_profile => 'مزامنة ملفك السحابي...';

  @override
  String get auth_google_sign_in_failed => 'فشل تسجيل الدخول عبر Google';

  @override
  String get auth_facebook_sign_in_failed => 'فشل تسجيل الدخول عبر Facebook';

  @override
  String auth_google_sign_in_failed_code(String code) {
    return 'فشل تسجيل الدخول عبر Google ($code). يرجى المحاولة مرة أخرى.';
  }

  @override
  String auth_firebase_google_sign_in_failed(String code) {
    return 'تعذر على Firebase إكمال تسجيل الدخول عبر Google ($code).';
  }

  @override
  String get barcode_unknown_product => 'منتج غير معروف';

  @override
  String get barcode_default_portion => 'لكل حصة/100 جم';

  @override
  String get activity_calorie_estimate_disclaimer =>
      'السعرات مقدّرة من الخطوات وقد لا تكون دقيقة تمامًا.';

  @override
  String get activity_estimated_calories => 'السعرات المقدّرة';

  @override
  String get activity_step_streak => 'سلسلة الخطوات';

  @override
  String get activity_workout_calories => 'سعرات التمارين';

  @override
  String get activity_score => 'درجة النشاط';

  @override
  String get log_health_title => 'صحة SnapCal';

  @override
  String get log_key_metrics => 'المقاييس الرئيسية';

  @override
  String get log_customize => 'تخصيص';

  @override
  String get log_metric_water => 'الماء';

  @override
  String get log_metric_energy_burned => 'الطاقة المحروقة';

  @override
  String get log_metric_steps => 'الخطوات';

  @override
  String get log_metric_calories_intake => 'السعرات المتناولة';

  @override
  String get log_macro_unlock_tracking => 'فتح تتبع المغذيات';

  @override
  String get log_metric_carbs => 'الكربوهيدرات';

  @override
  String get log_metric_fat => 'الدهون';

  @override
  String get log_metric_protein => 'البروتين';

  @override
  String get log_metric_steps_unit => 'خطوة';

  @override
  String get log_period_day => 'ي';

  @override
  String get log_period_week => 'أ';

  @override
  String get log_period_month => 'ش';

  @override
  String get log_period_three_months => '3ش';

  @override
  String get log_period_year => 'س';

  @override
  String get log_detail_this_day => 'هذا اليوم';

  @override
  String get log_detail_this_week => 'هذا الأسبوع';

  @override
  String get log_detail_this_month => 'هذا الشهر';

  @override
  String get log_detail_this_three_months => 'آخر 3 أشهر';

  @override
  String get log_detail_this_year => 'هذا العام';

  @override
  String log_metric_per_day_avg(String unit) {
    return '$unit يوميًا (متوسط)';
  }

  @override
  String get log_metric_goal_hit => 'أنت ضمن الهدف.';

  @override
  String get log_metric_goal_miss => 'لم تصل إلى هدفك.';

  @override
  String log_metric_left(String value) {
    return '$value متبقٍ';
  }

  @override
  String get log_metric_below_range => 'أقل من النطاق';

  @override
  String get log_metric_no_data => 'لا توجد بيانات';

  @override
  String get log_metric_locked => 'مقفل';

  @override
  String get log_metric_history_locked => 'السجل الكامل في Pro';

  @override
  String get log_metric_detail_list_title => 'هذه الفترة';

  @override
  String get common_days => 'أيام';

  @override
  String get aha_prompt_title => 'لقد وفرت للتو 10 دقائق';

  @override
  String get aha_prompt_subtitle =>
      'تخيل توفير هذا الوقت كل يوم. اشترك في Pro للحصول على عمليات مسح صور غير محدودة وتتبع سهل.';

  @override
  String get aha_prompt_btn => 'كن برو';

  @override
  String get macro_locked_title => 'المغذيات الكبرى ميزة Pro';

  @override
  String get macro_locked_body =>
      'افتح تفاصيل البروتين والكربوهيدرات والدهون مع SnapCal Pro.';

  @override
  String get macro_unlock_cta => 'افتح المغذيات الكبرى';

  @override
  String get macro_locked_placeholder => 'مقفل';

  @override
  String get macro_unlock_card_title => 'افتح تفصيل المغذيات لديك';

  @override
  String get macro_unlock_card_body =>
      'شاهد تقدم البروتين والكربوهيدрат والدهون لكل وجبة.';

  @override
  String get common_unlock => 'فتح';

  @override
  String get scan_choice_title => 'اختر نوع المسح';

  @override
  String get scan_choice_subtitle => 'سجل وجبة من صورة أو امسح طعاماً مغلفاً.';

  @override
  String get scan_choice_food_title => 'مسح الطعام';

  @override
  String get scan_choice_food_subtitle =>
      'استخدم الكاميرا لتقدير التغذية فوراً بالذكاء الاصطناعي.';

  @override
  String get scan_choice_barcode_title => 'مسح الباركود';

  @override
  String get scan_choice_barcode_subtitle =>
      'ابحث عن الطعام المغلف بواسطة الباركود.';

  @override
  String get planner_empty_headline => 'تخطيط ذكي ومخصص للوجبات لمدة 7 أيام';

  @override
  String get planner_empty_body =>
      'يبني SnapCal وجباتك حول السعرات والماكروز والتفضيلات واحتياجات التسوق.';

  @override
  String get planner_empty_benefit_adaptive => 'إرشاد يومي تكيفي';

  @override
  String get planner_empty_benefit_macros => 'وجبات متوازنة';

  @override
  String get planner_empty_benefit_grocery => 'قائمة تسوق';

  @override
  String get planner_adjust_preferences => 'تعديل التفضيلات';

  @override
  String get planner_meals_unit => 'وجبات';

  @override
  String get planner_items_unit => 'عناصر';

  @override
  String get planner_avg_plan => 'متوسط الخطة';

  @override
  String get planner_protein_coverage => 'البروتين';

  @override
  String get planner_guidance_protein =>
      'البروتين متأخر؛ اجعل الوجبة التالية غنية بالبروتين.';

  @override
  String get planner_guidance_light =>
      'السعرات محدودة؛ اجعل الوجبة التالية أخف.';

  @override
  String get planner_guidance_balanced =>
      'أنت على المسار؛ اتبع الوجبات المخططة.';

  @override
  String get planner_prep_time => 'وقت التحضير';

  @override
  String get planner_prep_quick => 'سريع';

  @override
  String get planner_prep_balanced => 'متوازن';

  @override
  String get planner_prep_batch => 'تحضير مسبق';

  @override
  String get planner_budget => 'الميزانية';

  @override
  String get planner_budget_value => 'اقتصادي';

  @override
  String get planner_budget_standard => 'قياسي';

  @override
  String get planner_budget_premium => 'فاخر';

  @override
  String get planner_advanced_preferences => 'تفضيلات متقدمة';

  @override
  String get planner_advanced_preferences_body =>
      'الحساسيات، والأطعمة غير المرغوبة، والمعدات، والحصص، وأيام التمرين ستأتي في ترقية لاحقة.';

  @override
  String get planner_swap_title => 'استبدال الوجبة';

  @override
  String get planner_swap_intent => 'اختر الهدف';

  @override
  String get planner_swap_lower_calorie => 'سعرات أقل';

  @override
  String get planner_swap_higher_protein => 'بروتين أعلى';

  @override
  String get planner_swap_faster_prep => 'تحضير أسرع';

  @override
  String get planner_swap_cheaper => 'أقل تكلفة';

  @override
  String get planner_swap_custom_note => 'إضافة ملاحظة اختيارية';

  @override
  String get planner_swap_note_hint => 'مثلاً دجاج، سلطة، مكرونة...';

  @override
  String get planner_swap_generate => 'إنشاء بديل';

  @override
  String get planner_swap_with_note => 'استبدال مع ملاحظة';

  @override
  String get planner_swap_loading => 'جارٍ البحث عن وجبة بديلة...';

  @override
  String get planner_swap_success => 'تم استبدال الوجبة ببديل عملي.';

  @override
  String get planner_grocery_ready => 'قائمة المتوفر لديك';

  @override
  String get planner_already_have => 'متوفر لديك';

  @override
  String get planner_rebalance_notice_light =>
      'تمت موازنة الخطة: الوجبات المتبقية أخف لهذا اليوم.';

  @override
  String get planner_rebalance_notice_protein =>
      'تمت موازنة الخطة: الوجبات المتبقية تركز على البروتين.';

  @override
  String get planner_today_plan => 'خطة اليوم';

  @override
  String get planner_today_meals => 'وجبات اليوم';

  @override
  String get planner_planned_unit => 'مخططة';

  @override
  String get planner_planned_for_today => 'مخطط لليوم';

  @override
  String get planner_logged => 'تم التسجيل';

  @override
  String get planner_upcoming => 'قادمة';

  @override
  String get planner_alert_next_protein => 'اجعل الوجبة التالية غنية بالبروتين';

  @override
  String get planner_alert_on_track => 'الخطة على المسار';

  @override
  String get planner_alert_follow_plan => 'اتبع الوجبة المخططة التالية';

  @override
  String get planner_alert_fix_it => 'تعديل';

  @override
  String get planner_week_complete_title => 'اكتملت خطة الوجبات هذه';

  @override
  String get planner_generate_current_week => 'إنشاء خطة هذا الأسبوع';

  @override
  String get settings_milliliters_unit => 'مل';

  @override
  String get log_customize_metrics_desc =>
      'اختر المقاييس التي تظهر في لوحة التحكم';

  @override
  String get log_metric_full_history_locked => 'السجل الكامل مقفل';

  @override
  String get log_metric_full_history_upgrade =>
      'اشترك في Pro لعرض السجل لأكثر من 14 يومًا';

  @override
  String planner_swap_replacing(Object food) {
    return 'استبدال: $food';
  }

  @override
  String planner_rebalance_notice_adjusted(Object count) {
    return 'تمت موازنة الخطة: تم تعديل $count من الوجبات المتبقية لهذا اليوم.';
  }

  @override
  String planner_alert_protein_short(Object grams) {
    return 'ينقصك $gramsغ بروتين اليوم';
  }

  @override
  String planner_week_complete_body(Object date) {
    return 'انتهت خطتك السابقة في $date. أنشئ خطة جديدة للأسبوع الحالي.';
  }

  @override
  String log_metric_goal_value(Object value) {
    return 'هدف $value';
  }

  @override
  String get onboarding_pace_title => 'اختر وتيرتك';

  @override
  String get onboarding_pace_error_target_required => 'أدخل وزن المستهدف أولاً';

  @override
  String get onboarding_pace_error_pace_required => 'اختر وتيرة للمتابعة';

  @override
  String get onboarding_pace_gentle => 'هادئ';

  @override
  String get onboarding_pace_gentle_desc => 'تقدم أبطأ، أسهل للحفاظ عليه';

  @override
  String get onboarding_pace_balanced => 'متوازن';

  @override
  String get onboarding_pace_balanced_desc => 'تقدم ثابت مع تعديل معتدل';

  @override
  String get onboarding_pace_faster => 'أسرع';

  @override
  String get onboarding_pace_faster_desc => 'نتائج سريعة، يحتاج تعديلاً أكثر';

  @override
  String get onboarding_pace_target_weight => 'الوزن المستهدف';

  @override
  String onboarding_pace_target_date(String date) {
    return 'الموعد المتوقع: $date';
  }

  @override
  String onboarding_pace_weekly_rate(String rate, String unit) {
    return '~$rate $unit/أسبوع';
  }

  @override
  String get onboarding_plan_title => 'خطتك جاهزة';

  @override
  String get onboarding_plan_explanation => 'أهداف مخصصة بناءً على معلوماتك';

  @override
  String get onboarding_plan_protein => 'بروتين';

  @override
  String get onboarding_plan_carbs => 'كربوهيدرات';

  @override
  String get onboarding_plan_fat => 'دهون';

  @override
  String onboarding_plan_grams(int grams) {
    return '$gramsغ';
  }

  @override
  String get onboarding_plan_start => 'بدء الخطة';

  @override
  String get onboarding_plan_adjust => 'تعديل';

  @override
  String get onboarding_plan_maintenance_estimate =>
      'الحفاظ على الوزن الحالي مع التغذية المتعقبة';

  @override
  String onboarding_goal_summary_lose(String rate, String unit) {
    return 'فقدان $rate $unit/أسبوع';
  }

  @override
  String get onboarding_goal_summary_maintain => 'الحفاظ على الوزن الحالي';

  @override
  String onboarding_goal_summary_build(String rate, String unit) {
    return 'بناء $rate $unit/أسبوع';
  }

  @override
  String get onboarding_goal_summary_track => 'تتبع التغذية بدون هدف وزن';

  @override
  String get onboarding_safety_zero_loss =>
      'وزنك الحالي يطابق وزنك المستهدف. سنركز على الحفاظ مع التغذية المتعقبة.';

  @override
  String get onboarding_safety_zero_gain =>
      'وزنك الحالي يطابق وزنك المستهدف. سنركز على الحفاظ مع التغذية المتعقبة.';

  @override
  String onboarding_safety_adjusted_detail(
    String originalRate,
    String unit,
    String actualRate,
  ) {
    return '$originalRate $unit كان مبالغًا فيه. عدلناه إلى $actualRate $unit لأسباب أمنية.';
  }

  @override
  String onboarding_safety_updated_goal(String date) {
    return 'تم تحديث المستهدف بحلول $date';
  }

  @override
  String get onboarding_safety_adjusted_fallback =>
      'عدّلنا خطتك لتكون آمنة وواقعية.';

  @override
  String get onboarding_adjusted_badge => 'تم التعديل';

  @override
  String get onboarding_profile_title => 'أخبرنا عن نفسك';

  @override
  String get onboarding_profile_weight => 'الوزن';

  @override
  String get onboarding_profile_sex_label => 'الجنس';

  @override
  String get onboarding_error_sex_required => 'اختر جنسك للمتابعة';

  @override
  String get onboarding_error_adult_only =>
      'يجب أن يكون عمرك 13 عامًا على الأقل';

  @override
  String get onboarding_already_account => 'لديك حساب بالفعل؟';

  @override
  String get onboarding_scan_meal_title => 'امسح وجبتك';

  @override
  String get onboarding_scan_scanning => 'جارٍ تحليل وجبتك...';

  @override
  String get onboarding_scan_ai_label => 'ذكاء اصطناعي';

  @override
  String get onboarding_scan_kcal => 'سعرة';

  @override
  String get onboarding_goal_title => 'ما هدفك؟';

  @override
  String get onboarding_goal_lose => 'فقدان الوزن';

  @override
  String get onboarding_goal_lose_desc => 'عجز سعرات لحرق الدهون';

  @override
  String get onboarding_goal_maintain => 'الحفاظ';

  @override
  String get onboarding_goal_maintain_desc => 'حافظ على وزنك الحالي مستقرًا';

  @override
  String get onboarding_goal_build => 'بناء العضلات';

  @override
  String get onboarding_goal_build_desc => 'فائض سعرات لزيادة الكتلة العضلية';

  @override
  String get onboarding_goal_track => 'تتبع فقط';

  @override
  String get onboarding_goal_track_desc => 'تسجيل الوجبات بدون هدف وزن';

  @override
  String get onboarding_activity_sitting => 'خامل';

  @override
  String get onboarding_activity_sitting_desc => 'عمل مكتبي، تمارين قليلة';

  @override
  String get onboarding_activity_light => 'خفيف';

  @override
  String get onboarding_activity_light_desc => '1-3 أيام تمارين أسبوعيًا';

  @override
  String get onboarding_activity_very => 'نشط جدًا';

  @override
  String get onboarding_activity_very_desc => '6-7 أيام تمارين أسبوعيًا';

  @override
  String get onboarding_plan_kcal_day => 'سعرات / يوم';

  @override
  String get onboarding_finish_error =>
      'تعذر إنشاء خطتك. يرجى المحاولة مرة أخرى.';

  @override
  String get onboarding_error_target_lower =>
      'يجب أن يكون المستهدف أقل من الوزن الحالي';

  @override
  String get onboarding_error_target_higher =>
      'يجب أن يكون المستهدف أعلى من الوزن الحالي';
}
