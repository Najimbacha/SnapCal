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
  String get log_track_prompt => 'تتبع وجباتك لتراها هنا.';

  @override
  String get log_no_data_prompt => 'لا توجد بيانات لهذا اليوم.';

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
}
