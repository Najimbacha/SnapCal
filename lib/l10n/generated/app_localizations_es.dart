// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SnapCal';

  @override
  String get ads_label => 'PUBLICIDAD';

  @override
  String get ads_remove_prompt => 'Quitar anuncios — Hazte Pro';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_skip => 'Omitir';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_back => 'Atrás';

  @override
  String get common_done => 'Hecho';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_offline_mode => 'Modo sin conexión';

  @override
  String get error_scan_failed =>
      'Error al escanear. Inténtalo de nuevo o ingresa manualmente.';

  @override
  String get error_barcode_not_found =>
      'Producto no encontrado. Intenta ingresarlo manualmente.';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_log => 'Diario';

  @override
  String get nav_stats => 'Estadísticas';

  @override
  String get nav_profile => 'Perfil';

  @override
  String get home_greeting_morning => 'Buenos días';

  @override
  String get home_greeting_afternoon => 'Buenas tardes';

  @override
  String get home_greeting_evening => 'Buenas noches';

  @override
  String get home_calories_remaining => 'Calorías restantes';

  @override
  String get home_calories_eaten => 'Consumidas';

  @override
  String get home_calories_burned => 'Quemadas';

  @override
  String get home_water_title => 'Ingesta de agua';

  @override
  String home_water_goal(int goal) {
    return 'Meta: ${goal}ml';
  }

  @override
  String get home_recent_meals => 'Comidas recientes';

  @override
  String get home_view_all => 'Ver todo';

  @override
  String home_streak_days(int count) {
    return 'Racha de $count días';
  }

  @override
  String get home_section_macros => 'Macros';

  @override
  String get home_section_actions => 'Acciones rápidas';

  @override
  String get home_action_log => 'Abrir registro';

  @override
  String get home_action_reports => 'Ver reportes';

  @override
  String get home_sync_prompt =>
      'Crea una cuenta para sincronizar tu progreso.';

  @override
  String get log_title => 'Registro Diario';

  @override
  String get log_subtitle => 'Sigue tu viaje nutricional';

  @override
  String get log_entries => 'ENTRADAS';

  @override
  String get log_total_kcal => 'KCAL TOTALES';

  @override
  String get log_history => 'HISTORIAL DE COMIDAS';

  @override
  String get log_no_entries_today => 'Sin registros hoy';

  @override
  String get log_no_entries_history => 'Historial vacío';

  @override
  String get log_track_prompt => 'Registra tus comidas para verlas aquí.';

  @override
  String get log_no_data_prompt => 'No hay datos para este día.';

  @override
  String get log_add_manually => 'Agregar Manualmente';

  @override
  String log_removed_snackbar(String food) {
    return '$food eliminado';
  }

  @override
  String get assistant_title => 'Entrenador IA';

  @override
  String get assistant_status => 'Siempre activo';

  @override
  String get assistant_initial_prompt => '¿Cómo puedo ayudarte hoy?';

  @override
  String get assistant_initial_body =>
      'Tu entrenador personal de SnapCal está listo para ayudarte con recetas, metas y consejos nutricionales.';

  @override
  String get assistant_preparing => 'Preparando tu viaje de bienestar...';

  @override
  String get assistant_input_hint => 'Escribe un mensaje...';

  @override
  String get assistant_input_listening => 'Escuchando...';

  @override
  String get assistant_needs_connection => 'El asistente necesita conexión.';

  @override
  String get assistant_clear_title => '¿Borrar chat?';

  @override
  String get assistant_clear_body =>
      'Esto eliminará tu historial de conversación con el entrenador.';

  @override
  String get assistant_clear_confirm => 'Borrar';

  @override
  String get assistant_starter_meal_title => 'Ideas de Comidas';

  @override
  String get assistant_starter_meal_desc => 'Cenas altas en proteínas';

  @override
  String get assistant_starter_cal_title => 'Control de Calorías';

  @override
  String get assistant_starter_cal_desc => '¿Cómo voy hoy?';

  @override
  String get assistant_starter_tips_title => 'Consejos';

  @override
  String get assistant_starter_tips_desc => 'Controlar antojos nocturnos';

  @override
  String get assistant_starter_plans_title => 'Planes';

  @override
  String get assistant_starter_plans_desc => 'Crear plan de 3 días';

  @override
  String get premium_welcome => '¡Bienvenido a SnapCal Pro! 🎉';

  @override
  String get premium_restore_success => '¡Compras restauradas! 🎉';

  @override
  String get premium_restore_empty => 'No se encontraron compras anteriores.';

  @override
  String get premium_restore_fail => 'Error al restaurar compras.';

  @override
  String get premium_plan_yearly => 'Anual';

  @override
  String get premium_plan_6months => '6 Meses';

  @override
  String get premium_plan_3months => '3 Meses';

  @override
  String get premium_plan_2months => '2 Meses';

  @override
  String get premium_plan_monthly => 'Mensual';

  @override
  String get premium_plan_weekly => 'Semanal';

  @override
  String get premium_plan_lifetime => 'De por vida';

  @override
  String get premium_per_month => '/mes';

  @override
  String get premium_free_trial => 'prueba gratuita';

  @override
  String get premium_start_trial => 'Iniciar Prueba Gratuita';

  @override
  String premium_start_plan(String plan, String price) {
    return 'Iniciar $plan — $price';
  }

  @override
  String get premium_loading => 'Cargando...';

  @override
  String get snap_align_food => 'Alinea la comida en el marco';

  @override
  String get snap_analyzing => 'Analizando tu comida...';

  @override
  String get snap_retake => 'Repetir';

  @override
  String get snap_log_meal => 'Registrar esta comida';

  @override
  String get result_energy => 'Energía';

  @override
  String get result_protein => 'Proteína';

  @override
  String get result_carbs => 'Carbohidratos';

  @override
  String get result_fat => 'Grasas';

  @override
  String get result_portion => 'Tamaño de la porción';

  @override
  String get result_save_success => '¡Comida registrada con éxito!';

  @override
  String get result_health => 'SALUD';

  @override
  String get result_kcal => 'KCAL';

  @override
  String get result_macronutrients => 'MACRONUTRIENTES';

  @override
  String get result_logging_portion => 'PORCIÓN DE REGISTRO';

  @override
  String result_ai_estimate(int percent) {
    return '$percent% de la estimación de IA';
  }

  @override
  String result_daily_goal_info(int percent) {
    return 'Esta comida es el $percent% de tu meta diaria de energía.';
  }

  @override
  String get planner_title => 'Planificador de Comidas';

  @override
  String get planner_smart_title => 'Planificador Inteligente';

  @override
  String get planner_empty_state => 'No hay plan para hoy';

  @override
  String get planner_generate => 'Generar Plan con IA';

  @override
  String get planner_daily_goal => 'Meta Diaria';

  @override
  String get planner_tab_weekly => 'Plan Semanal';

  @override
  String get planner_tab_grocery => 'Lista de Compras';

  @override
  String get planner_day_mon => 'Lun';

  @override
  String get planner_day_tue => 'Mar';

  @override
  String get planner_day_wed => 'Mié';

  @override
  String get planner_day_thu => 'Jue';

  @override
  String get planner_day_fri => 'Vie';

  @override
  String get planner_day_sat => 'Sáb';

  @override
  String get planner_day_sun => 'Dom';

  @override
  String planner_no_meals(Object day) {
    return 'No hay comidas para el $day';
  }

  @override
  String planner_regenerate_day(Object day) {
    return '¿Regenerar el $day?';
  }

  @override
  String get planner_grocery_empty => 'Aún no hay lista de compras';

  @override
  String get planner_grocery_pro => 'La lista de compras es Pro';

  @override
  String get planner_share => 'Compartir';

  @override
  String get planner_creating => 'Creando tu plan';

  @override
  String get planner_msg_calories => 'Calculando tus necesidades calóricas...';

  @override
  String get planner_msg_meals =>
      'Eligiendo las mejores comidas para tu meta...';

  @override
  String get planner_msg_macros => 'Equilibrando tus macros...';

  @override
  String get planner_msg_grocery => 'Construyendo tu lista de compras...';

  @override
  String get planner_msg_ready => 'Casi listo...';

  @override
  String get error_offline => 'Sin conexión: análisis de IA no disponible';

  @override
  String get error_camera => 'Cámara no disponible';

  @override
  String get error_generic => 'Algo salió mal';

  @override
  String get sync_title => 'Sincronización en la nube';

  @override
  String get sync_subtitle =>
      'Mantén tus datos de salud seguros en todos tus dispositivos con una cuenta.';

  @override
  String get sync_benefit_devices => 'Sincroniza en todos tus dispositivos';

  @override
  String get sync_benefit_progress => 'Nunca pierdas tu progreso';

  @override
  String get sync_benefit_offline =>
      'Funciona sin conexión, sincroniza al conectar';

  @override
  String get sync_benefit_secure => 'Tus datos están cifrados y seguros';

  @override
  String get sync_google => 'Continuar con Google';

  @override
  String get sync_facebook => 'Continuar con Facebook';

  @override
  String get sync_email => 'Iniciar sesión con Email';

  @override
  String get sync_skip => 'Omitir por ahora';

  @override
  String get splash_tagline => 'Captura. Registra. Prospera.';

  @override
  String get notif_breakfast_title => 'Recordatorio de Desayuno';

  @override
  String get notif_breakfast_body =>
      '¡Es hora de registrar tu desayuno saludable!';

  @override
  String get notif_lunch_title => 'Recordatorio de Almuerzo';

  @override
  String get notif_lunch_body => 'No olvides registrar tu almuerzo.';

  @override
  String get notif_dinner_title => 'Recordatorio de Cena';

  @override
  String get notif_dinner_body =>
      'Termina el día con fuerza: registra tu cena ahora.';

  @override
  String get auth_title => 'Tu viaje\ncomienza aquí';

  @override
  String get auth_subtitle =>
      'Captura, registra y domina tu nutrición en segundos.';

  @override
  String get auth_divider_email => 'O usa tu correo';

  @override
  String get auth_hint_email => 'Correo electrónico';

  @override
  String get auth_hint_password => 'Contraseña';

  @override
  String get auth_btn_signup => 'Crear mi cuenta';

  @override
  String get auth_btn_signin => 'Iniciar sesión con Email';

  @override
  String get auth_footer_member => '¿Ya eres miembro? ';

  @override
  String get auth_footer_new => '¿Nuevo en SnapCal? ';

  @override
  String get auth_action_signin => 'Iniciar sesión';

  @override
  String get auth_action_join => 'Únete ahora';

  @override
  String get auth_msg_success => '¡Inicio de sesión exitoso!';

  @override
  String auth_msg_welcome(String name) {
    return '¡Bienvenido de nuevo, $name!';
  }

  @override
  String get result_meal_breakfast => 'Desayuno';

  @override
  String get result_meal_lunch => 'Almuerzo';

  @override
  String get result_meal_dinner => 'Cena';

  @override
  String get result_meal_snack => 'Merienda';

  @override
  String get result_macro_power => 'FUERZA';

  @override
  String get result_macro_energy => 'ENERGÍA';

  @override
  String get result_macro_lean => 'LIGERO';

  @override
  String get common_hero => 'HÉROE';

  @override
  String get notif_goal_calories_title => '¡Objetivo Alcanzado! 🚀';

  @override
  String notif_goal_calories_body(Object goal) {
    return '¡Has alcanzado tu objetivo diario de $goal kcal!';
  }

  @override
  String get notif_goal_protein_title => '¡Meta de Proteína Cumplida! 💪';

  @override
  String notif_goal_protein_body(Object goal) {
    return '¡Buen trabajo! Has alcanzado tu meta de ${goal}g de proteína.';
  }

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_save_progress => 'Guardar progreso';

  @override
  String get common_delete_permanently => 'Eliminar permanentemente';

  @override
  String get common_try_again => 'Reintentar';

  @override
  String get common_try_reload => 'Recargar';

  @override
  String get common_sign_out => 'Cerrar sesión';

  @override
  String get common_sign_out_confirm =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get common_delete_account => '¿Eliminar cuenta?';

  @override
  String get common_delete_account_confirm =>
      'Esta acción es permanente. Se perderán todos tus datos.';

  @override
  String get settings_save_name => 'Guardar nombre';

  @override
  String get settings_log_weight_first =>
      'Registra tu peso primero para recalcular.';

  @override
  String get settings_complete_profile_first =>
      'Completa tu perfil primero (edad, género, altura, meta).';

  @override
  String get settings_age => 'Edad';

  @override
  String get settings_gender => 'Género';

  @override
  String get settings_units => 'Unidades';

  @override
  String get settings_weight_unit => 'Unidad de peso';

  @override
  String get settings_height_unit => 'Unidad de altura';

  @override
  String get settings_breakfast_time => 'Recordatorio de desayuno';

  @override
  String get settings_lunch_time => 'Recordatorio de almuerzo';

  @override
  String get settings_dinner_time => 'Recordatorio de cena';

  @override
  String get planner_unlock_week => 'Desbloquear semana completa';

  @override
  String get planner_upgrade_pro => 'Pasar a Pro';

  @override
  String get planner_regenerate => 'Regenerar';

  @override
  String get planner_meal_preferences => 'Preferencias de comidas';

  @override
  String get planner_meals_per_day => 'Comidas al día';

  @override
  String get planner_dietary_restriction => 'Restricción dietética';

  @override
  String get planner_cuisine_style => 'Estilo de cocina';

  @override
  String get planner_generate_plan => 'Generar mi plan';

  @override
  String get assistant_mic_permission =>
      'Se requiere permiso de micrófono para entrada de voz.';

  @override
  String get assistant_added_to_diary => '¡Añadido a tu diario! 🍎';

  @override
  String assistant_plan_updated(String key, String value) {
    return 'Plan actualizado: $key es ahora $value';
  }

  @override
  String get water_add_water => 'Añadir agua';

  @override
  String get water_add => 'Añadir';

  @override
  String get water_hydration => 'Hidratación';

  @override
  String get water_tracker => 'Seguimiento de hidratación';

  @override
  String water_reached(int amount, int goal) {
    return '$amount de $goal ml alcanzado';
  }

  @override
  String get water_custom => 'Personalizado';

  @override
  String get water_enter_amount => 'Ingresa la cantidad';

  @override
  String get progress_tap_to_snap => 'Toca para capturar';

  @override
  String get progress_compare_previous => 'Comparar con anterior';

  @override
  String get log_delete_meal_title => '¿Eliminar comida?';

  @override
  String get log_delete_meal_body =>
      'Esto eliminará permanentemente esta comida de tu diario.';

  @override
  String get settings_title => 'Ajustes';

  @override
  String get settings_display_name => 'Nombre de usuario';

  @override
  String get settings_how_to_call => '¿Cómo deberíamos llamarte?';

  @override
  String settings_enter_value(String title) {
    return 'Ingresa tu $title abajo';
  }

  @override
  String get settings_core_config => 'Configuración central';

  @override
  String get settings_data_security => 'Datos y seguridad';

  @override
  String get settings_information => 'Información';

  @override
  String get settings_body_profile => 'Perfil corporal';

  @override
  String get settings_body_profile_sub => 'Actualiza tus estadísticas y metas';

  @override
  String get settings_nutrition_goals => 'Metas de nutrición';

  @override
  String get settings_nutrition_goals_sub =>
      'Objetivos diarios de calorías y macros';

  @override
  String get settings_preferences => 'Preferencias';

  @override
  String get settings_preferences_sub => 'Ajustes de tema y notificaciones';

  @override
  String get settings_account => 'Cuenta';

  @override
  String get settings_account_sub => 'Membresía y seguridad del perfil';

  @override
  String get settings_data_sync => 'Datos y sincronización';

  @override
  String get settings_data_sync_sub => 'Opciones de exportación y respaldo';

  @override
  String get settings_about => 'Acerca de';

  @override
  String get settings_about_sub => 'Términos, privacidad e información';

  @override
  String get report_title => 'Informes';

  @override
  String get report_subtitle => 'Sigue tu éxito a largo plazo';

  @override
  String get report_tab_nutrition => 'Nutrición';

  @override
  String get report_tab_body => 'Cuerpo';

  @override
  String get report_weekly_review => 'Revisión Semanal';

  @override
  String get report_monthly_audit => 'Auditoría mensual';

  @override
  String get report_failed => 'Error al generar el informe';

  @override
  String get paywall_welcome => '¡Bienvenido a SnapCal Pro! 🎉';

  @override
  String get progress_log_progress => 'Registrar Progreso';

  @override
  String get progress_take_photos_desc => 'Toma fotos para seguir tu viaje.';

  @override
  String get progress_front_view => 'Vista Frontal';

  @override
  String get progress_side_view => 'Vista Lateral';

  @override
  String get progress_saving => 'Guardando...';

  @override
  String get progress_save_progress => 'Guardar Progreso';

  @override
  String get progress_comparison => 'Comparación';

  @override
  String progress_weight_diff(String diff) {
    return '$diff kg de diferencia';
  }

  @override
  String get progress_before => 'Antes';

  @override
  String get progress_after => 'Después';

  @override
  String get progress_missing_photos => 'Faltan fotos para la comparación.';

  @override
  String get progress_front => 'Frontal';

  @override
  String get progress_side => 'Lateral';

  @override
  String get progress_failed_camera => 'Error al abrir la cámara.';

  @override
  String get assistant_attached_image => 'Imagen adjunta';

  @override
  String get home_body_stats => 'Estadísticas corporales';

  @override
  String get log_edit_meal => 'Editar Comida';

  @override
  String get log_log_new_meal => 'Registrar Nueva Comida';

  @override
  String get log_food_name => 'Nombre de la comida';

  @override
  String get log_portion_desc => 'Descripción de la porción';

  @override
  String get log_calories_kcal => 'Calorías (kcal)';

  @override
  String get log_save_entry => 'Guardar Entrada';

  @override
  String get log_delete_entry => 'Eliminar Entrada';

  @override
  String get log_food_hint => 'ej. Tostada de aguacate';

  @override
  String get log_protein_g => 'Proteína (g)';

  @override
  String get log_carbs_g => 'Carbohidratos (g)';

  @override
  String get log_fat_g => 'Grasa (g)';

  @override
  String get common_keep_it => 'Mantener';

  @override
  String get planner_target => 'Objetivo';

  @override
  String get planner_setup_desc => 'Configuración rápida antes de tu plan';

  @override
  String get planner_ai_disclaimer =>
      'Este plan es generado por IA solo para orientación general.';

  @override
  String get planner_restriction_none => 'Ninguno';

  @override
  String get planner_restriction_vegetarian => 'Vegetariano';

  @override
  String get planner_restriction_vegan => 'Vegano';

  @override
  String get planner_restriction_gluten_free => 'Sin gluten';

  @override
  String get planner_restriction_keto => 'Keto';

  @override
  String get planner_restriction_halal => 'Halal';

  @override
  String get planner_cuisine_international => 'Internacional';

  @override
  String get planner_cuisine_south_asian => 'Sur de Asia';

  @override
  String get planner_cuisine_mediterranean => 'Mediterránea';

  @override
  String get planner_cuisine_east_asian => 'Este de Asia';

  @override
  String get planner_cuisine_american => 'Americana';

  @override
  String get planner_cuisine_middle_eastern => 'Medio Oriente';

  @override
  String get snap_offline_error =>
      'El análisis por IA requiere conexión a internet.';

  @override
  String get home_metric_goal => 'Meta';

  @override
  String get home_metric_meals => 'Comidas';

  @override
  String get home_metric_goal_hint => 'Meta diaria';

  @override
  String get home_metric_meals_hint => 'Registradas hoy';

  @override
  String get home_no_meals_title => 'Sin comidas registradas';

  @override
  String get home_no_meals_body => 'Empieza con una foto rápida.';

  @override
  String get home_default_name => 'Amigo';

  @override
  String get log_portion_hint => 'ej. 1 tazón, 200g, 1 rebanada';

  @override
  String get log_unknown_food => 'Comida desconocida';

  @override
  String get home_goal_reached => 'META';

  @override
  String get home_completed => 'COMPLETADO';

  @override
  String get home_kcal_left => 'kcal restantes';

  @override
  String get assistant_typing => 'El entrenador está escribiendo...';

  @override
  String get assistant_retry => 'Reintentar';

  @override
  String get assistant_speech_not_available =>
      'Reconocimiento de voz no disponible';

  @override
  String get paywall_pro_plan => 'PLAN PRO';

  @override
  String get paywall_unlock_unlimited => 'Desbloqueo Ilimitado';

  @override
  String get paywall_subtitle => 'Experimenta todo el poder del entrenador IA.';

  @override
  String get paywall_feature_unlimited => 'Ilimitado';

  @override
  String get paywall_feature_scans => 'Scans Diarios';

  @override
  String get paywall_feature_smart => 'Inteligente';

  @override
  String get paywall_feature_plans => 'Planes de Comida';

  @override
  String get paywall_feature_coach => 'Entrenador IA';

  @override
  String get paywall_feature_advice => 'Consejos Proactivos';

  @override
  String get paywall_feature_ads => 'Sin Anuncios';

  @override
  String get paywall_feature_no_ads => 'Cero Interrupciones';

  @override
  String get paywall_best_value => 'MEJOR VALOR';

  @override
  String get paywall_restore => 'Restaurar Compras';

  @override
  String get paywall_purchase_failed =>
      'Error en la compra. Inténtalo de nuevo.';

  @override
  String paywall_save_percent(Object percent) {
    return 'AHORRA $percent%';
  }

  @override
  String get paywall_trial_title => 'Cómo funciona tu prueba';

  @override
  String get paywall_trial_today => 'Hoy';

  @override
  String get paywall_trial_today_desc =>
      'Obtienes acceso completo a todas las funciones Pro.';

  @override
  String paywall_trial_reminder(Object day) {
    return 'Día $day';
  }

  @override
  String get paywall_trial_reminder_desc =>
      'Te enviaremos un recordatorio de que tu prueba termina.';

  @override
  String paywall_trial_end(Object day) {
    return 'Día $day';
  }

  @override
  String get paywall_trial_end_desc =>
      'Se realizará el cargo. Cancela antes para evitarlo.';

  @override
  String get paywall_referral_title => '¿Lo quieres gratis?';

  @override
  String get paywall_referral_subtitle =>
      'Invita amigos para ganar scans extra.';

  @override
  String paywall_then(Object price) {
    return 'Luego $price';
  }

  @override
  String get settings_select_language => 'Seleccionar Idioma';

  @override
  String get settings_language_desc =>
      'Elige tu idioma preferido para la interfaz';

  @override
  String get settings_lang_en_desc => 'Idioma predeterminado';

  @override
  String get settings_lang_ar_desc => 'Árabe (Soporte RTL)';

  @override
  String get settings_lang_es_desc => 'Español';

  @override
  String get settings_lang_fr_desc => 'Francés';

  @override
  String get settings_appearance => 'Apariencia';

  @override
  String get settings_theme_system => 'Sistema';

  @override
  String get settings_theme_light => 'Claro';

  @override
  String get settings_theme_dark => 'Oscuro';

  @override
  String get settings_data_sync_title => 'Datos y Sincronización';

  @override
  String get settings_export_data => 'Exportar datos';

  @override
  String get settings_export_desc => 'Descarga tus comidas y métricas';

  @override
  String get settings_cloud_sync_desc =>
      'Inicia sesión para respaldar tus datos';

  @override
  String get settings_about_title => 'Acerca de';

  @override
  String get settings_privacy => 'Política de privacidad';

  @override
  String get settings_privacy_desc => 'Cómo manejamos tus datos';

  @override
  String get settings_terms => 'Términos de servicio';

  @override
  String get settings_terms_desc => 'Condiciones de uso';

  @override
  String get settings_about_snapcal => 'Sobre SnapCal';

  @override
  String get settings_upgrade_pro => 'Pasar a Pro';

  @override
  String get settings_upgrade_desc =>
      'Desbloquea scans ilimitados y entrenador IA';

  @override
  String get planner_free_limit_body => 'Usuarios gratis solo ven Lun y Mar.';

  @override
  String get planner_grocery_empty_body =>
      'Genera un plan primero y tu lista aparecerá aquí.';

  @override
  String get planner_grocery_pro_body =>
      'Pasa a Pro para gestionar tu lista de compras.';

  @override
  String planner_regenerate_body(String day) {
    return 'Esto reemplazará las comidas del $day por opciones frescas.';
  }

  @override
  String get planner_setup_body =>
      'Cuéntanos tus metas y crearemos un plan de 7 días para ti.';

  @override
  String get planner_no_meals_body => 'Intenta regenerar este día.';

  @override
  String get report_weekly => 'Semanal';

  @override
  String get report_monthly => 'Mensual';

  @override
  String onboarding_step(int current, int total) {
    return 'PASO $current DE $total';
  }

  @override
  String get onboarding_get_started => 'Empezar';

  @override
  String get onboarding_start_journey => 'Iniciar mi viaje';

  @override
  String get onboarding_continue => 'Continuar';

  @override
  String get onboarding_welcome_title => 'Tu meta.\nTus calorías.\nTu ritmo.';

  @override
  String get onboarding_welcome_body =>
      'Responde unas preguntas para establecer tu objetivo calórico diario.';

  @override
  String get onboarding_basic_intro_eyebrow => 'DETALLES PERSONALES';

  @override
  String get onboarding_basic_intro_title => 'Establece tus métricas base.';

  @override
  String get onboarding_basic_intro_body =>
      'Usamos esto para calcular tu tasa metabólica en reposo (RMR).';

  @override
  String get onboarding_age => 'Edad';

  @override
  String get onboarding_age_suffix => 'años';

  @override
  String get onboarding_gender => 'Género';

  @override
  String get onboarding_male => 'Masculino';

  @override
  String get onboarding_female => 'Femenino';

  @override
  String get onboarding_height => 'Altura';

  @override
  String get onboarding_weight_intro_eyebrow => 'ESTADO ACTUAL';

  @override
  String get onboarding_weight_intro_title => '¿Cuánto pesas hoy?';

  @override
  String get onboarding_weight_intro_body =>
      'Esto nos ayuda a entender tu punto de partida.';

  @override
  String get onboarding_weight_footer =>
      'Sin juicios. Cada viaje empieza con una métrica honesta.';

  @override
  String get onboarding_target_intro_eyebrow => 'EL OBJETIVO';

  @override
  String get onboarding_target_intro_title => '¿Cuál es tu peso ideal?';

  @override
  String get onboarding_target_intro_body =>
      'Estructuraremos tus calorías para alcanzar esta meta en tu plazo.';

  @override
  String get onboarding_target_maintain_title => 'Mantener peso';

  @override
  String get onboarding_target_maintain_body =>
      'Crearemos un plan para mantener tu peso estable.';

  @override
  String get onboarding_timeline => 'Plazo del Objetivo';

  @override
  String onboarding_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Meses',
      one: 'Mes',
    );
    return '$count $_temp0';
  }

  @override
  String get onboarding_activity_eyebrow => 'ESTILO DE VIDA';

  @override
  String get onboarding_activity_title => '¿Qué tan activo eres?';

  @override
  String get onboarding_activity_body =>
      'Sé honesto, es el factor más grande en tu quema calórica.';

  @override
  String get onboarding_activity_sedentary => 'Sedentario';

  @override
  String get onboarding_activity_sedentary_desc =>
      'Trabajo de oficina, poco ejercicio';

  @override
  String get onboarding_activity_lightly => 'Ligeramente activo';

  @override
  String get onboarding_activity_lightly_desc => '1-3 días de ejercicio/semana';

  @override
  String get onboarding_activity_moderately => 'Moderadamente activo';

  @override
  String get onboarding_activity_moderately_desc =>
      '3-5 días de ejercicio/semana';

  @override
  String get onboarding_activity_active => 'Muy activo';

  @override
  String get onboarding_activity_active_desc => '3-5 días/semana';

  @override
  String get onboarding_result_eyebrow => 'TU PLAN';

  @override
  String get onboarding_result_title => 'Tu objetivo está listo.';

  @override
  String get onboarding_result_kcal_day => 'kcal / día';

  @override
  String onboarding_result_reach_by(String date) {
    return 'Alcanzarás tu meta el $date';
  }

  @override
  String onboarding_result_pace(String pace, String unit) {
    return 'Ritmo: $pace $unit / semana';
  }

  @override
  String get onboarding_error_age => 'Ingresa una edad entre 13 y 100.';

  @override
  String get onboarding_error_height => 'Ingresa una altura realista.';

  @override
  String get onboarding_error_weight => 'Ingresa un peso actual realista.';

  @override
  String get onboarding_error_goal_weight => 'Ingresa un peso ideal realista.';

  @override
  String get onboarding_error_timeline =>
      'Ajusta tu plazo para un plan válido.';

  @override
  String get onboarding_error_generic =>
      'No pudimos crear tu plan. Inténtalo de nuevo.';

  @override
  String get onboarding_result_loading_eyebrow => 'Resultado IA';

  @override
  String get onboarding_result_loading_title =>
      'Construyendo tu objetivo calórico.';

  @override
  String get onboarding_result_loading_body =>
      'Estamos combinando tus métricas en un plan listo para usar.';

  @override
  String get onboarding_result_calibrating =>
      'Calibrando tu objetivo diario...';

  @override
  String get onboarding_result_error_eyebrow => 'ERROR DE CÁLCULO';

  @override
  String get onboarding_result_error_title => 'No pudimos terminar tu plan.';

  @override
  String get onboarding_result_error_body => 'Intenta el último paso de nuevo.';

  @override
  String get onboarding_result_success_eyebrow => 'CALIBRACIÓN IA COMPLETA';

  @override
  String get onboarding_result_success_title => 'Objetivo diario listo.';

  @override
  String get onboarding_result_success_body =>
      'Este número está personalizado para tu cuerpo.';

  @override
  String get onboarding_result_minor_warning =>
      'Consulta a un profesional antes de empezar restricciones calóricas.';

  @override
  String get onboarding_result_daily_calories => 'CALORÍAS DIARIAS';

  @override
  String get onboarding_result_strategy => 'Estrategia';

  @override
  String get onboarding_result_recommendation => 'Recomendación';

  @override
  String get onboarding_activity_desk_life => 'Vida de escritorio';

  @override
  String get onboarding_activity_desk_life_desc => 'Poco o nada de ejercicio';

  @override
  String get onboarding_activity_light_mover => 'Movimiento ligero';

  @override
  String get onboarding_activity_light_mover_desc => '1-3 días/semana';

  @override
  String get onboarding_activity_active_title => 'Activo';

  @override
  String get onboarding_activity_athlete => 'Atleta';

  @override
  String get onboarding_activity_athlete_desc => '6-7 días/semana';

  @override
  String get onboarding_activity_footer => 'Activo seleccionado por defecto.';

  @override
  String get onboarding_feature_target => 'Objetivo calórico personal';

  @override
  String get onboarding_feature_macros => 'División de macros';

  @override
  String get onboarding_feature_insight => 'Perspectiva IA';

  @override
  String get planner_meal => 'Comida';

  @override
  String get planner_ingredients => 'Ingredientes';

  @override
  String get common_mins => 'min';

  @override
  String planner_kcal_total(int goal) {
    return '/ $goal kcal';
  }

  @override
  String planner_kcal_over(int delta) {
    return '+$delta exceso';
  }

  @override
  String planner_kcal_under(int delta) {
    return '$delta bajo';
  }

  @override
  String get planner_kcal_on_target => 'En objetivo';

  @override
  String get snap_gallery => 'Galería';

  @override
  String get snap_barcode => 'Código de barras';

  @override
  String get snap_pro_unlimited => '∞ Pro';

  @override
  String get snap_bento_plate => 'Plato Bento';

  @override
  String snap_items_detected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ítems detectados',
      one: 'ítem detectado',
    );
    return '$count $_temp0.';
  }

  @override
  String get snap_total_meal => 'TOTAL COMIDA';

  @override
  String snap_items_selected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ítems seleccionados',
      one: 'ítem seleccionado',
    );
    return '$count $_temp0';
  }

  @override
  String get settings_body_profile_title => 'Perfil corporal';

  @override
  String get settings_body_profile_desc =>
      'Gestiona tus métricas físicas y objetivos.';

  @override
  String get settings_display_name_label => 'Nombre de usuario';

  @override
  String get settings_set_name => 'Establecer nombre';

  @override
  String get settings_current_weight => 'Peso actual';

  @override
  String get settings_set_weight => 'Establecer peso';

  @override
  String get settings_height => 'Altura';

  @override
  String get settings_set_height => 'Establecer altura';

  @override
  String get settings_target_weight => 'Peso ideal';

  @override
  String get settings_set_target => 'Establecer objetivo';

  @override
  String get settings_nutrition_goals_title => 'Metas de nutrición';

  @override
  String get settings_daily_calories => 'Calorías diarias';

  @override
  String get settings_protein => 'Proteínas';

  @override
  String get settings_carbs => 'Carbohidratos';

  @override
  String get settings_fat => 'Grasas';

  @override
  String get settings_optimize_btn => 'Optimizar mi plan nutricional';

  @override
  String get settings_optimizing => 'Optimizando plan...';

  @override
  String get settings_recalculate_query =>
      'Acabo de optimizar mi plan de nutrición. Por favor, explica por qué se eligieron estas calorías y macros específicos para mí según mi perfil.';

  @override
  String get settings_guest_account => 'Cuenta de invitado';

  @override
  String get settings_member => 'Miembro de SnapCal';

  @override
  String get settings_auth_cta => 'Regístrate o Inicia sesión';

  @override
  String get settings_preferences_title => 'Preferencias';

  @override
  String get settings_notifications => 'Notificaciones';

  @override
  String get settings_meal_reminders => 'Recordatorios de comidas';

  @override
  String get settings_language => 'Idioma';

  @override
  String get settings_account_title => 'Cuenta';

  @override
  String get settings_subscription => 'Suscripción';

  @override
  String get settings_pro_active => 'Pro activo';

  @override
  String get settings_manage_plan => 'Gestionar plan';

  @override
  String get settings_create_account => 'Crear cuenta';

  @override
  String get settings_sign_out_desc => 'Salir de esta sesión';

  @override
  String get settings_sync_data_desc => 'Sincroniza tus datos';

  @override
  String get settings_about_app => 'Acerca de SnapCal';

  @override
  String get settings_legalese =>
      '© 2026 SnapCal. Todos los derechos reservados.';

  @override
  String get onboarding_result_maintain => 'Mantener peso actual';

  @override
  String onboarding_result_weekly_rate(String rate) {
    return '~$rate kg / semana';
  }

  @override
  String get error_connection_title => 'Problema de conexión';

  @override
  String get error_connection_body =>
      'No se pudo inicializar SnapCal. Verifica tus datos o Wi-Fi.';

  @override
  String get error_unexpected_title => 'Algo salió mal';

  @override
  String get error_unexpected_body =>
      'Encontramos un error inesperado. Nuestro equipo ha sido notificado y estamos trabajando para solucionarlo.';

  @override
  String get report_guest_user => 'Usuario valioso';

  @override
  String get report_avg_calories => 'Calorías promedio';

  @override
  String get report_consistency => 'Consistencia';

  @override
  String get report_calorie_trend => 'Tendencia de calorías';

  @override
  String get report_macro_dist => 'Distribución de macros';

  @override
  String get report_macro_protein => 'Proteína';

  @override
  String get report_macro_carbs => 'Carbohidratos';

  @override
  String get report_macro_fat => 'Grasa';

  @override
  String get report_no_weight_title => 'Aún no hay entradas de peso';

  @override
  String get report_no_weight_body =>
      'Agrega tu primera entrada para que comience tu tendencia corporal.';

  @override
  String get report_log_weight => 'Registrar peso';

  @override
  String get report_weight_current => 'Actual';

  @override
  String get report_weight_change => 'Cambio';

  @override
  String get report_progress_timeline => 'Cronología de progreso';

  @override
  String get report_progress_gallery =>
      'Galería visual de transformación corporal';

  @override
  String get report_weight_analytics => 'Análisis de peso';

  @override
  String get report_recent_history => 'Historial reciente';

  @override
  String report_body_fat_pct(String percent) {
    return '$percent% Grasa';
  }

  @override
  String get weight_hint => 'Peso';

  @override
  String get body_fat_hint => 'Grasa corporal (opcional)';

  @override
  String get snap_scan_barcode => 'Escanear código de barras';

  @override
  String get snap_barcode_hint =>
      'Coloca el código de barras dentro del marco.';

  @override
  String get snap_torch => 'Linterna';

  @override
  String get snap_flip => 'Girar';
}
