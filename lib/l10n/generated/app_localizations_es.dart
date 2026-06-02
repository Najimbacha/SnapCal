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
  String get log_return_today => 'Volver a hoy';

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
  String get result_calories => 'Calorías';

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
  String get notif_meal_reminders_channel => 'Recordatorios de comidas';

  @override
  String get notif_meal_reminders_channel_description =>
      'Recordatorios para registrar tu nutrición diaria.';

  @override
  String get notif_daily_motivation_channel => 'Motivación diaria';

  @override
  String get notif_daily_motivation_channel_description =>
      'Motivación diaria y amable de nutrición de SnapCal.';

  @override
  String get notif_motivation_1_title => 'Los pasos pequeños cuentan';

  @override
  String get notif_motivation_1_body =>
      'Registra tu primera comida cuando estés listo.';

  @override
  String get notif_motivation_2_title => 'Hoy empieza simple';

  @override
  String get notif_motivation_2_body =>
      'Elige una comida que apoye tu objetivo.';

  @override
  String get notif_motivation_3_title => 'Una buena elección';

  @override
  String get notif_motivation_3_body =>
      'Empieza con proteína, agua o un registro rápido.';

  @override
  String get notif_motivation_4_title => 'No necesitas perfección';

  @override
  String get notif_motivation_4_body => 'Solo observa lo que comes hoy.';

  @override
  String get notif_motivation_5_title => 'Primero, energía';

  @override
  String get notif_motivation_5_body => 'Dale a tu cuerpo algo útil hoy.';

  @override
  String get notif_motivation_6_title => 'Hazlo fácil';

  @override
  String get notif_motivation_6_body =>
      'Registra una comida. Eso ya construye el hábito.';

  @override
  String get notif_motivation_7_title => 'Construye bien el día';

  @override
  String get notif_motivation_7_body =>
      'Una primera comida equilibrada facilita la siguiente.';

  @override
  String get notif_motivation_8_title => 'Tu salud es diaria';

  @override
  String get notif_motivation_8_body =>
      'Un pequeño registro te mantiene en control.';

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
  String get notif_goal_alerts_channel => 'Alertas de objetivos';

  @override
  String get notif_goal_alerts_channel_description =>
      'Alertas cuando alcanzas tus metas de nutrición.';

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
  String get water_remove => 'Quitar';

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
  String get home_first_meal_cta_title => 'Escanea una comida para empezar hoy';

  @override
  String get home_first_meal_cta_body =>
      'Usa la cámara para registrar calorías y macros automáticamente.';

  @override
  String get home_section_macros_today => 'Macros de hoy';

  @override
  String get home_eaten_progress => 'CONSUMIDO';

  @override
  String get home_steps_today => 'pasos hoy';

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
  String get settings_sign_in => 'Iniciar sesión';

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
  String get settings_daily_motivation => 'Motivación diaria';

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

  @override
  String get settings_health_sync => 'Sincronización de salud';

  @override
  String get settings_health_sync_sub =>
      'Sincronizar pasos y calorías quemadas';

  @override
  String get home_metric_activity => 'Actividad';

  @override
  String get home_metric_activity_sync => 'Sincronizar';

  @override
  String get home_metric_activity_enable => 'Activar salud';

  @override
  String get progress_generate_video => 'Generar video del viaje';

  @override
  String get progress_video_failed =>
      'Error al generar el video. Inténtalo de nuevo.';

  @override
  String get progress_video_min_photos =>
      '¡Toma al menos 2 fotos de progreso primero!';

  @override
  String get progress_video_share_text =>
      '¡Mi viaje de transformación en SnapCal! 🚀';

  @override
  String get widget_status_on_track => 'En camino';

  @override
  String get widget_status_over_goal => 'Meta superada';

  @override
  String get widget_status_almost_there => 'Casi listo';

  @override
  String get feature_insights_title => 'Resumen Semanal';

  @override
  String get feature_insights_desc => 'Tu semana en revisión';

  @override
  String feature_insights_avg_cal(String cal) {
    return 'Promedio $cal kcal/día';
  }

  @override
  String feature_insights_on_track(String days) {
    return '$days Días en camino';
  }

  @override
  String get feature_insights_generating => 'Generando perspectivas...';

  @override
  String get feature_insights_share => 'Compartir mi semana';

  @override
  String get feature_templates_title => 'Mis Rutinas';

  @override
  String get feature_templates_empty =>
      '¡Guarda tu primera rutina! Registra un combo, luego toca \'Guardar como Rutina\'.';

  @override
  String get feature_templates_save_prompt => '¿Guardar como Rutina?';

  @override
  String get feature_templates_name_hint => 'ej. Desayuno';

  @override
  String get feature_templates_save_btn => 'Guardar Rutina';

  @override
  String get feature_templates_update_btn => 'Actualizar Rutina';

  @override
  String get feature_templates_limit_reached =>
      'Límite gratuito alcanzado. ¡Actualiza a Pro para rutinas ilimitadas!';

  @override
  String get feature_templates_logged => '¡Rutina registrada con éxito!';

  @override
  String get feature_achievements_title => 'Logros';

  @override
  String feature_achievements_unlocked(String count) {
    return '$count Desbloqueados';
  }

  @override
  String get achievement_first_flame => 'Primera Llama';

  @override
  String get achievement_first_flame_desc => 'Registra tu primera comida';

  @override
  String get achievement_consistency_king => 'Rey de la Constancia';

  @override
  String get achievement_consistency_king_desc => 'Racha de 7 días';

  @override
  String get achievement_iron_will => 'Voluntad de Hierro';

  @override
  String get achievement_iron_will_desc => 'Racha de 30 días';

  @override
  String get achievement_unstoppable => 'Imparable';

  @override
  String get achievement_unstoppable_desc => 'Racha de 100 días';

  @override
  String get achievement_bullseye => 'En el Blanco';

  @override
  String get achievement_bullseye_desc =>
      'Alcanza la meta de calorías exactamente';

  @override
  String get achievement_precision_pro => 'Pro de la Precisión';

  @override
  String get achievement_precision_pro_desc =>
      'Meta de calorías durante 7 días seguidos';

  @override
  String get achievement_macro_master => 'Maestro de Macros';

  @override
  String get achievement_macro_master_desc =>
      'Alcanza todos los macros en un día';

  @override
  String get achievement_perfect_week => 'Semana Perfecta';

  @override
  String get achievement_perfect_week_desc =>
      'Alcanza todas las metas por 7 días';

  @override
  String get achievement_first_sip => 'Primer Sorbo';

  @override
  String get achievement_first_sip_desc => 'Registra agua por primera vez';

  @override
  String get achievement_hydration_hero => 'Héroe de la Hidratación';

  @override
  String get achievement_hydration_hero_desc => 'Meta de agua por 30 días';

  @override
  String get achievement_ocean_mode => 'Modo Océano';

  @override
  String get achievement_ocean_mode_desc => 'Meta de agua por 100 días';

  @override
  String get achievement_first_snap => 'Primer Snap';

  @override
  String get achievement_first_snap_desc => 'Registra 1 comida por cámara';

  @override
  String get achievement_snap_master => 'Maestro del Snap';

  @override
  String get achievement_snap_master_desc => 'Registra 100 comidas';

  @override
  String get achievement_snap_legend => 'Leyenda del Snap';

  @override
  String get achievement_snap_legend_desc => 'Registra 500 comidas';

  @override
  String get achievement_first_checkin => 'Primer Chequeo';

  @override
  String get achievement_first_checkin_desc =>
      'Registra primera foto del cuerpo';

  @override
  String get achievement_transformation => 'Transformación';

  @override
  String get achievement_transformation_desc => 'Registra 10 fotos del cuerpo';

  @override
  String get achievement_journey_video => 'Video del Viaje';

  @override
  String get achievement_journey_video_desc =>
      'Generar video de transformación';

  @override
  String get feature_achievements_unlocked_title => '¡Logro Desbloqueado!';

  @override
  String get common_continue => 'Continuar';

  @override
  String get feature_insights_subtitle =>
      '¡Tu resumen nutricional semanal con IA está listo!';

  @override
  String get feature_insights_share_text =>
      '¡Mira mi resumen nutricional semanal de SnapCal! 📊';

  @override
  String get settings_guest_title => 'Protege tu progreso';

  @override
  String get settings_guest_subtitle =>
      'Inicia sesión para sincronizar tus datos de forma segura.';

  @override
  String get activity_tracking_status => 'ESTADO DE SEGUIMIENTO';

  @override
  String get activity_active => 'Activo';

  @override
  String get activity_description =>
      'Los sensores de tu teléfono están rastreando activamente tus pasos para el gasto calórico de hoy.';

  @override
  String get activity_authorize_desc =>
      'Para rastrear tus pasos automáticamente, por favor autoriza el reconocimiento de actividad.';

  @override
  String get activity_authorize_btn => 'Autorizar Seguimiento';

  @override
  String get activity_motivation_low => 'Cada paso cuenta. ¡A moverse hoy!';

  @override
  String get activity_motivation_mid =>
      '¡Vas por buen camino! Una caminata rápida te ayudaría a llegar a tu meta.';

  @override
  String get activity_motivation_high =>
      '¡Casi allí! Estás superando tus metas de actividad.';

  @override
  String get activity_motivation_elite =>
      '¡Sobresaliente! Estás en la zona activa de élite hoy.';

  @override
  String get home_scan_food => 'Escanear comida';

  @override
  String get home_go_pro => 'Pasar a Pro';

  @override
  String get home_pro_badge => 'PRO';

  @override
  String get settings_upgrade_to_pro => 'MEJORAR A PRO';

  @override
  String get settings_emerald_badge => 'ESMERALDA';

  @override
  String get coach_limit_title => 'LÍMITE DIARIO ALCANZADO';

  @override
  String get coach_limit_subtitle =>
      'Pásate a Premium para obtener asesoramiento ilimitado y orientación de comidas más inteligente adaptada a tus objetivos.';

  @override
  String get coach_limit_btn => 'Mejorar para Chat Ilimitado';

  @override
  String get coach_see_options => 'Ver opciones de suscripción';

  @override
  String get coach_locked_title => 'Saber qué comer a continuación.';

  @override
  String get coach_locked_desc =>
      'El entrenador de IA lee las calorías, macros y objetivos de hoy, luego brinda consejos claros sobre la comida.';

  @override
  String get coach_preview_meal_title => 'Sugerencia de la próxima comida';

  @override
  String get coach_preview_meal_body =>
      'Mejor comida siguiente: tazón de arroz con pollo a la parrilla, alrededor de 550 kcal.';

  @override
  String get coach_preview_macro_title => 'Corrección de macros';

  @override
  String get coach_preview_macro_body =>
      'Aún necesitas 45g de proteína y 120g de carbohidratos hoy.';

  @override
  String get coach_preview_feedback_title => 'Comentarios del progreso diario';

  @override
  String get coach_preview_feedback_body =>
      'Estás bajo en proteínas. Agrega huevos, atún o yogur griego a continuación.';

  @override
  String get report_prompt_title => 'TU REPORTE SEMANAL ESTÁ LISTO';

  @override
  String get report_prompt_subtitle =>
      'Desbloquea una mirada más profunda sobre por qué algunos días superaron el objetivo y cómo mejorar la próxima semana.';

  @override
  String get report_prompt_btn => 'Desbloquear reporte semanal';

  @override
  String get scan_overlay_scanning => 'ESCANEO DE VISIÓN DE IA';

  @override
  String get scan_overlay_desc =>
      'Detectando ingredientes y calculando la densidad nutricional con Gemini...';

  @override
  String get scan_overlay_manual => 'REGISTRAR MANUALMENTE';

  @override
  String get report_card_title => 'INFORME DE PROGRESO SEMANAL';

  @override
  String get report_card_subtitle =>
      'Mira por qué algunos días superaron el objetivo y recibe sugerencias personalizadas para corregirlo.';

  @override
  String get startup_launch_issue => 'Hubo un problema al iniciar';

  @override
  String get startup_initialization_slow =>
      'La inicialización está tardando más de lo esperado.';

  @override
  String get startup_setup_failed =>
      'Algo salió mal al configurar la app. Inténtalo de nuevo.';

  @override
  String get startup_retry_launch => 'Reintentar inicio';

  @override
  String get startup_initialization_error => 'Error de inicialización';

  @override
  String get startup_error_body =>
      'La aplicación encontró un error al iniciar. Intenta reiniciarla.';

  @override
  String get startup_reload => 'Recargar';

  @override
  String get activity_live_tracking => 'SEGUIMIENTO EN VIVO';

  @override
  String get activity_stationary => 'SIN MOVIMIENTO';

  @override
  String get activity_steps_today_label => 'PASOS HOY';

  @override
  String get activity_calories_label => 'CALORÍAS';

  @override
  String get activity_goal_label => 'OBJETIVO';

  @override
  String get activity_tracking_engine => 'MOTOR DE SEGUIMIENTO';

  @override
  String get activity_active_encrypted => 'Activo y cifrado';

  @override
  String get activity_permission_required => 'Permiso requerido';

  @override
  String get activity_steps_synced =>
      'Tus pasos se sincronizan en tiempo real.';

  @override
  String get activity_enable_tracking =>
      'Activa el seguimiento para ver tu progreso.';

  @override
  String feature_insights_share_error(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String get feature_insights_empty => 'Aún no hay datos para esta semana.';

  @override
  String get feature_insights_calorie_trend => 'Tendencia de calorías';

  @override
  String get feature_insights_ai_coach => 'Consejos del coach IA';

  @override
  String get auth_intro_body =>
      'Tu camino hacia una vida más saludable empieza aquí.';

  @override
  String get auth_back_to_social => 'Volver al inicio social';

  @override
  String get auth_create_account => 'Crear cuenta';

  @override
  String get auth_welcome_back_title => 'Bienvenido de nuevo';

  @override
  String get home_welcome_guest => 'Bienvenido a SnapCal';

  @override
  String get auth_lets_dive => 'Empecemos';

  @override
  String get auth_sign_up_short => 'Registrarse';

  @override
  String get auth_log_in => 'Iniciar sesión';

  @override
  String get auth_have_account => '¿Ya tienes cuenta? ';

  @override
  String get auth_no_account => '¿No tienes cuenta? ';

  @override
  String get common_or => 'o';

  @override
  String get common_today => 'Hoy';

  @override
  String get common_yesterday => 'Ayer';

  @override
  String get common_tomorrow => 'Mañana';

  @override
  String get common_maybe_later => 'Quizás más tarde';

  @override
  String get settings_category_body_profile_sub =>
      'Métricas corporales, unidades y peso objetivo';

  @override
  String get settings_category_nutrition_sub =>
      'Objetivos de calorías, proteínas, carbohidratos y grasas';

  @override
  String get settings_category_preferences_sub =>
      'Tema, idioma, recordatorios y planificación de comidas';

  @override
  String get settings_category_achievements_sub =>
      'Rachas, logros y recompensas de progreso';

  @override
  String get settings_category_account_sub =>
      'Inicio de sesión, nombre de perfil y controles de cuenta';

  @override
  String get settings_category_data_sync_sub =>
      'Copia de seguridad, restauración y datos locales';

  @override
  String get settings_category_about_sub =>
      'Versión, privacidad, términos e información de la app';

  @override
  String get home_go_deeper_title => 'Ver más detalles';

  @override
  String get home_go_deeper_body =>
      'Revisiones diarias con IA, tendencias de macros e historial completo.';

  @override
  String get home_daily_wellness => 'Bienestar diario';

  @override
  String get home_add => 'Agregar';

  @override
  String get home_daily_score => 'Puntuación diaria';

  @override
  String get log_monthly_calendar_soon =>
      'El calendario mensual llegará pronto';

  @override
  String get log_today_subtitle => 'Registra lo que comes hoy';

  @override
  String get log_review_day => 'Revisar este día';

  @override
  String get log_scan_food => 'Escanear comida';

  @override
  String get feature_templates_saved_meals => 'COMIDAS GUARDADAS';

  @override
  String get feature_templates_saved_added => 'Comida guardada agregada';

  @override
  String get feature_templates_deleted => 'Rutina eliminada';

  @override
  String get premium_analysis_title => 'ANÁLISIS PREMIUM';

  @override
  String get premium_analysis_body =>
      'Obtén una mejor versión de esta comida según tu objetivo con sugerencias de IA.';

  @override
  String get result_meal_name => 'Nombre de la comida';

  @override
  String get result_feast => 'Banquete';

  @override
  String get result_ai_meal_insight => 'Análisis IA de la comida';

  @override
  String get result_ai_meal_body =>
      'Equilibra esta comida con una sugerencia inteligente.';

  @override
  String get result_add_new_item => 'AGREGAR NUEVO ELEMENTO';

  @override
  String get result_total_calories => 'CALORÍAS TOTALES';

  @override
  String get result_food_details => 'Detalles de comida';

  @override
  String get result_food => 'Comida';

  @override
  String get result_portion_label => 'Porción';

  @override
  String get result_add_item => 'Add Item';

  @override
  String get result_nutrition_details => 'Nutrition Details';

  @override
  String get result_unlock_nutrition => 'Unlock nutrition details';

  @override
  String get result_add_to_log => 'Add to Log';

  @override
  String get paywall_cancel_anytime =>
      'Cancela cuando quieras. Sin compromiso.';

  @override
  String get paywall_terms_conditions => 'Términos y condiciones';

  @override
  String get paywall_trial_7_day => 'Prueba de 7 días';

  @override
  String get paywall_scan_limit_subtitle =>
      'Usaste 3/3 escaneos gratis hoy. Desbloquea escaneos ilimitados con IA y desglose instantáneo de calorías.';

  @override
  String get paywall_coach_subtitle =>
      'Desbloquea coaching ilimitado, orientación de macros y sugerencias de comidas adaptadas a tu día.';

  @override
  String get paywall_planner_subtitle =>
      'Desbloquea planes semanales completos, listas de compras, preferencias y regeneración de comidas con IA.';

  @override
  String paywall_reports_subtitle(String feature) {
    return 'Desbloquea análisis más profundos, tendencias semanales y sugerencias prácticas de IA después de cada $feature.';
  }

  @override
  String get paywall_progress_subtitle =>
      'Desbloquea más fotos de progreso, comparaciones y seguimiento de transformación más allá del límite mensual gratis.';

  @override
  String get paywall_ad_removal_subtitle =>
      'Pásate a Pro para quitar anuncios y desbloquear toda la experiencia nutricional con IA.';

  @override
  String get progress_weight_trend => 'Tendencia de peso';

  @override
  String get progress_log_custom_weight =>
      'Toca para registrar tu peso personalizado';

  @override
  String get log_calories_eaten => 'Calorías consumidas';

  @override
  String log_kcal_over(int amount) {
    return '$amount por encima';
  }

  @override
  String log_kcal_left(int amount) {
    return '$amount restantes';
  }

  @override
  String get log_no_details => 'Aún no hay detalles registrados para este día.';

  @override
  String log_over_target_insight(int amount) {
    return 'Registraste $amount kcal por encima del objetivo. Revisa las comidas más pesadas abajo.';
  }

  @override
  String log_low_protein_insight(int calories) {
    return 'Registraste $calories kcal y la proteína quedó por debajo del objetivo.';
  }

  @override
  String log_water_behind_insight(int calories) {
    return 'Registraste $calories kcal. El agua aún está por debajo hoy.';
  }

  @override
  String log_balanced_day_insight(int calories) {
    return 'Registraste $calories kcal con un día equilibrado hasta ahora.';
  }

  @override
  String feature_templates_save_desc(int count) {
    return 'Guarda estos $count elementos para registrarlos luego con un toque.';
  }

  @override
  String get achievement_category_consistency => 'Constancia';

  @override
  String get achievement_category_precision => 'Precisión';

  @override
  String get achievement_category_hydration => 'Hidratación';

  @override
  String get achievement_category_logging => 'Registro';

  @override
  String get achievement_category_progress => 'Progreso';

  @override
  String get achievement_unlocked_label => 'Desbloqueado';

  @override
  String get report_pdf_title => 'INFORME NUTRICIONAL IA';

  @override
  String report_pdf_user(String name) {
    return 'Usuario: $name';
  }

  @override
  String get report_pdf_weekly_performance => 'RENDIMIENTO SEMANAL';

  @override
  String get report_pdf_total_protein => 'Proteína total';

  @override
  String get report_pdf_active_streak => 'Racha activa';

  @override
  String get report_pdf_grams => 'gramos';

  @override
  String get report_pdf_days => 'días';

  @override
  String get report_pdf_macro_distribution => 'DISTRIBUCIÓN DE MACRONUTRIENTES';

  @override
  String get report_pdf_nutrient => 'Nutriente';

  @override
  String get report_pdf_total_consumed => 'Total consumido';

  @override
  String get report_pdf_daily_target => 'Objetivo diario';

  @override
  String get report_pdf_goal_status => 'Estado del objetivo';

  @override
  String get report_pdf_carbohydrates => 'Carbohidratos';

  @override
  String get report_pdf_fats => 'Grasas';

  @override
  String get report_pdf_meal_log =>
      'REGISTRO DETALLADO DE COMIDAS (últimos 7 días)';

  @override
  String get report_pdf_date => 'Fecha';

  @override
  String get report_pdf_meal_item => 'Comida';

  @override
  String get report_pdf_type => 'Tipo';

  @override
  String get report_pdf_footer =>
      'Este informe fue generado automáticamente por SnapCal AI.';

  @override
  String get report_pdf_tagline => 'Mantén la constancia, cuida tu salud.';

  @override
  String get onboarding_safety_safer_pace => 'Sugeriremos un ritmo más seguro.';

  @override
  String get onboarding_safety_surplus_capped =>
      'Limitamos el superávit para mantener el plan realista.';

  @override
  String get onboarding_safety_floor =>
      'Mantuvimos tu objetivo por encima del mínimo seguro de calorías.';

  @override
  String onboarding_safety_floor_extra(String note) {
    return '$note Se aplicó el mínimo seguro de calorías.';
  }

  @override
  String onboarding_insight_desk(int calories) {
    return '$calories kcal mantiene tu plan realista para una rutina de baja actividad.';
  }

  @override
  String onboarding_insight_light(int calories) {
    return '$calories kcal te da un objetivo estable para movimiento semanal ligero.';
  }

  @override
  String onboarding_insight_athlete(int calories) {
    return '$calories kcal apoya la demanda del entrenamiento sin forzar demasiado el ritmo.';
  }

  @override
  String onboarding_insight_default(int calories) {
    return '$calories kcal equilibra tu objetivo, tamaño corporal y actividad actual.';
  }

  @override
  String get onboarding_tip_desk =>
      'Caminar 20 minutos después de comer es una forma fácil de mejorar la constancia.';

  @override
  String get onboarding_tip_light =>
      'Dos sesiones extra de movimiento por semana harán este objetivo más sostenible.';

  @override
  String get onboarding_tip_athlete =>
      'Distribuye proteína en cada comida para apoyar la recuperación y controlar el apetito.';

  @override
  String get onboarding_tip_bulk =>
      'Coloca la mayoría de calorías extra cerca del entrenamiento para mejorar el rendimiento.';

  @override
  String get onboarding_tip_default =>
      'Construye tus comidas alrededor de la proteína para que el objetivo sea más fácil.';

  @override
  String get paywall_slide_grilled_chicken => 'Pollo a la parrilla';

  @override
  String get paywall_slide_rice => 'Arroz';

  @override
  String get paywall_slide_avocado => 'Aguacate';

  @override
  String get paywall_slide_toast => 'Tostadas';

  @override
  String get paywall_slide_cherry_tomatoes => 'Tomates cherry';

  @override
  String get paywall_slide_salmon => 'Filete de salmón';

  @override
  String get paywall_slide_sweet_potato => 'Batata dulce';

  @override
  String get paywall_slide_broccoli => 'Brócoli';

  @override
  String get paywall_slide_boiled_eggs => 'Huevos cocidos';

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
  String get paywall_slide_eggs_portion => '2 grandes';

  @override
  String get paywall_slide_toast_portion => '2 rebanadas';

  @override
  String get scan_step_uploading => 'Subiendo imagen de la comida...';

  @override
  String get scan_step_scanning => 'Escaneando formas visuales...';

  @override
  String get scan_step_ingredients => 'Identificando ingredientes...';

  @override
  String get scan_step_portions => 'Estimando tamaños de porción...';

  @override
  String get scan_step_calories => 'Calculando densidad calórica...';

  @override
  String get scan_step_macros => 'Equilibrando macronutrientes...';

  @override
  String get scan_step_finalizing => 'Finalizando tarjeta de nutrición...';

  @override
  String get common_camera => 'Cámara';

  @override
  String get assistant_quick_macros => 'Corregir mis macros';

  @override
  String get assistant_quick_next_meal => '¿Qué debería comer ahora?';

  @override
  String get assistant_quick_snack => 'Snack alto en proteína';

  @override
  String assistant_meals_logged_today(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basado en $count comidas registradas hoy',
      one: 'Basado en 1 comida registrada hoy',
      zero: 'Basado en ninguna comida registrada hoy',
    );
    return '$_temp0';
  }

  @override
  String get assistant_ask_coach_header => 'Pregunta a tu entrenador';

  @override
  String get assistant_brief_today => 'Resumen del entrenador de hoy';

  @override
  String get assistant_live => 'En vivo';

  @override
  String get assistant_brief_left => 'Restante';

  @override
  String get assistant_protein_gap => 'Déficit de proteína';

  @override
  String get assistant_to_goal => 'para la meta';

  @override
  String get assistant_last_meal => 'Última comida';

  @override
  String get assistant_next_move => 'Siguiente paso';

  @override
  String get assistant_no_meals_logged => 'Sin comidas registradas aún';

  @override
  String get assistant_action_log_meal =>
      'Registra una comida para asesoramiento preciso';

  @override
  String get assistant_action_protein => 'Prioriza la proteína a continuación';

  @override
  String get assistant_action_light => 'Mantén la siguiente opción ligera';

  @override
  String get assistant_action_balanced =>
      'Mantén el equilibrio en tu próxima comida';

  @override
  String get assistant_analyze_image_prompt => 'Analiza esta imagen.';

  @override
  String common_items_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String get settings_weight_loss_progress => 'Progreso de pérdida de peso';

  @override
  String get settings_weight_gain_progress => 'Progreso de ganancia de peso';

  @override
  String get settings_weight_start => 'Inicio';

  @override
  String get settings_weight_current => 'Actual';

  @override
  String get settings_weight_target => 'Objetivo';

  @override
  String get settings_goal_reached => '¡Objetivo alcanzado! 🎉';

  @override
  String settings_left_to_reach_target(String amount, String unit) {
    return 'Faltan $amount $unit para alcanzar el objetivo';
  }

  @override
  String get settings_macro_calorie_split =>
      'Distribución de calorías de macros';

  @override
  String get settings_macro_calorie_split_desc =>
      'Porcentaje de calorías totales aportadas por cada macro';

  @override
  String get settings_step_tracking => 'Seguimiento de pasos';

  @override
  String get settings_syncing_activity => 'Sincronizando datos de actividad...';

  @override
  String get settings_sync_now => 'Sincronizar ahora';

  @override
  String get settings_sync_now_desc => 'Actualizar pasos y calorías estimadas';

  @override
  String settings_last_synced(String time) {
    return 'Última sincronización $time';
  }

  @override
  String get settings_disconnect_steps => 'Desactivar seguimiento de pasos';

  @override
  String get settings_disconnect_steps_desc =>
      'Dejar de escuchar las actualizaciones de pasos del teléfono';

  @override
  String get settings_status_enabled => 'Seguimiento activado';

  @override
  String get settings_status_denied => 'Permiso denegado';

  @override
  String get settings_status_unsupported => 'Dispositivo no compatible';

  @override
  String get settings_status_error => 'Error de seguimiento';

  @override
  String get settings_status_off => 'Seguimiento desactivado';

  @override
  String get settings_gender_male => 'Masculino';

  @override
  String get settings_gender_female => 'Femenino';

  @override
  String get settings_gender_other => 'Otro';

  @override
  String get settings_age_unit => 'años';

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
  String get paywall_unlock_snapcal_pro => 'Desbloquear SnapCal Pro';

  @override
  String get paywall_barcode_title => 'Desbloquear escáner de códigos';

  @override
  String get paywall_barcode_subtitle =>
      'Registra alimentos envasados al instante escaneando sus códigos';

  @override
  String get paywall_free_scans_used_title => 'Usaste 3/3 escaneos gratis hoy';

  @override
  String get paywall_unlimited_scanning_subtitle =>
      'Mejora para desbloquear escaneos ilimitados';

  @override
  String get paywall_unlimited_scanning_title =>
      'Desbloquear escaneos ilimitados';

  @override
  String get paywall_scan_track_subtitle =>
      'Mejora para escanear y registrar todas tus comidas';

  @override
  String get paywall_ai_coaching_title =>
      'Desbloquear coaching de IA ilimitado';

  @override
  String get paywall_ai_coaching_subtitle => 'Guía nutricional personal 24/7';

  @override
  String get paywall_smart_planning_title =>
      'Desbloquear planificación inteligente';

  @override
  String get paywall_smart_planning_subtitle =>
      'Planes diarios personalizados para tus objetivos';

  @override
  String get paywall_shopping_lists_title => 'Listas de compra automáticas';

  @override
  String get paywall_shopping_lists_subtitle =>
      'Ahorra tiempo con agregación inteligente de compras';

  @override
  String get paywall_progress_journey_title => 'Progreso visual';

  @override
  String get paywall_progress_journey_subtitle =>
      'Sigue tus fotos de transformación corporal';

  @override
  String get paywall_analytics_title => 'Analíticas metabólicas avanzadas';

  @override
  String get paywall_analytics_subtitle =>
      'Desbloquea tendencias nutricionales personalizadas';

  @override
  String get paywall_focused_title => 'Experiencia 100% enfocada';

  @override
  String get paywall_focused_subtitle =>
      'Elimina todos los anuncios e interrupciones';

  @override
  String get paywall_upgrade_experience_title => 'Mejora tu experiencia';

  @override
  String get paywall_upgrade_experience_subtitle =>
      'Desbloquea todas las funciones premium hoy';

  @override
  String get paywall_benefit_unlimited_scans => 'Escaneos ilimitados';

  @override
  String get paywall_benefit_ai_guidance => 'Guía con IA';

  @override
  String get paywall_benefit_full_history => 'Historial completo';

  @override
  String get paywall_benefit_weekly_reports => 'Informes semanales';

  @override
  String get paywall_benefit_ad_free => 'Sin anuncios';

  @override
  String get paywall_benefit_smart_planner => 'Planificador inteligente';

  @override
  String paywall_price_target(String price) {
    return '$price objetivo';
  }

  @override
  String get paywall_billing_monthly => 'Facturado mensualmente';

  @override
  String get paywall_billing_lifetime => 'Pago único';

  @override
  String get assistant_action_fix_macros => 'Ajustar mis macros de hoy';

  @override
  String get assistant_action_plan_next_meal => 'Planear mi próxima comida';

  @override
  String get assistant_action_light_dinner => 'Sugerir una cena ligera';

  @override
  String assistant_coaching_with_meals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coaching con $count comidas registradas hoy',
      one: 'Coaching con 1 comida registrada hoy',
      zero: 'Coaching sin comidas registradas hoy',
    );
    return '$_temp0';
  }

  @override
  String get assistant_start_new_chat => 'Iniciar un chat nuevo';

  @override
  String get assistant_new_chat => 'Chat nuevo';

  @override
  String get assistant_coach_insight => 'Consejo del coach';

  @override
  String get assistant_recipe_estimated_macros =>
      'Plan de receta con macros estimados';

  @override
  String get assistant_personalized_from_today =>
      'Personalizado según tu nutrición de hoy';

  @override
  String get assistant_step_recipe_plan => 'Plan de receta paso a paso';

  @override
  String get assistant_recipe => 'Receta';

  @override
  String get assistant_ingredients => 'Ingredientes';

  @override
  String get assistant_what_to_do => 'Qué hacer';

  @override
  String get assistant_recipe_plan => 'Plan de receta';

  @override
  String get assistant_plan_meal => 'Planear comida';

  @override
  String get assistant_adjust_macros => 'Ajustar macros';

  @override
  String get assistant_ask_follow_up => 'Preguntar seguimiento';

  @override
  String activity_steps_goal(int steps) {
    return 'Objetivo: $steps pasos';
  }

  @override
  String get activity_unlock_pro_title =>
      'Desbloquea funciones Pro de actividad';

  @override
  String get activity_unlock_pro_subtitle =>
      'Pásate a Pro para desbloquear ajuste dinámico del objetivo calórico por pasos, rachas semanales, calorías de entrenamientos manuales, puntuación de actividad e insights.';

  @override
  String get activity_manual_workouts => 'Entrenamientos manuales';

  @override
  String get activity_no_manual_workouts =>
      'No hay entrenamientos manuales registrados hoy.';

  @override
  String get activity_default_workout => 'Entrenamiento';

  @override
  String get activity_add_workout => 'Añadir entrenamiento';

  @override
  String get activity_workout_type => 'Tipo de entrenamiento';

  @override
  String get activity_minutes => 'Minutos';

  @override
  String get activity_save_workout => 'Guardar entrenamiento';

  @override
  String activity_insight_goal_met(int steps) {
    return 'Promediaste $steps pasos esta semana y estás cumpliendo tu objetivo.';
  }

  @override
  String activity_insight_goal_gap(int steps) {
    return 'Promediaste $steps pasos esta semana. Una caminata corta puede ayudarte a cerrar la brecha.';
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
      'Inicializando el motor inteligente de calorías...';

  @override
  String get splash_status_database => 'Abriendo base de datos cifrada...';

  @override
  String get splash_status_ai_gateways =>
      'Configurando el coach de IA y Gemini...';

  @override
  String get splash_status_dashboard => 'Calibrando el panel de bienestar...';

  @override
  String get splash_status_sync_profile => 'Sincronizando perfil en la nube...';

  @override
  String get auth_google_sign_in_failed => 'Error al iniciar sesión con Google';

  @override
  String get auth_facebook_sign_in_failed =>
      'Error al iniciar sesión con Facebook';

  @override
  String auth_google_sign_in_failed_code(String code) {
    return 'Error al iniciar sesión con Google ($code). Inténtalo de nuevo.';
  }

  @override
  String auth_firebase_google_sign_in_failed(String code) {
    return 'Firebase no pudo completar el inicio de sesión con Google ($code).';
  }

  @override
  String get barcode_unknown_product => 'Producto desconocido';

  @override
  String get barcode_default_portion => 'por porción/100 g';

  @override
  String get activity_calorie_estimate_disclaimer =>
      'Las calorías se estiman a partir de los pasos y pueden no ser exactas.';

  @override
  String get activity_estimated_calories => 'Calorías estimadas';

  @override
  String get activity_step_streak => 'Racha de pasos';

  @override
  String get activity_workout_calories => 'Calorías de entrenamientos';

  @override
  String get activity_score => 'Puntuación de actividad';

  @override
  String get log_health_title => 'Salud SnapCal';

  @override
  String get log_key_metrics => 'Métricas clave';

  @override
  String get log_customize => 'Personalizar';

  @override
  String get log_metric_water => 'Agua';

  @override
  String get log_metric_energy_burned => 'Energía quemada';

  @override
  String get log_metric_steps => 'Pasos';

  @override
  String get log_metric_calories_intake => 'Calorías ingeridas';

  @override
  String get log_macro_unlock_tracking => 'Unlock macro tracking';

  @override
  String get log_metric_carbs => 'Carbohidratos';

  @override
  String get log_metric_fat => 'Grasa';

  @override
  String get log_metric_protein => 'Proteína';

  @override
  String get log_metric_steps_unit => 'pasos';

  @override
  String get log_period_day => 'D';

  @override
  String get log_period_week => 'S';

  @override
  String get log_period_month => 'M';

  @override
  String get log_period_three_months => '3M';

  @override
  String get log_period_year => 'A';

  @override
  String get log_detail_this_day => 'Este día';

  @override
  String get log_detail_this_week => 'Esta semana';

  @override
  String get log_detail_this_month => 'Este mes';

  @override
  String get log_detail_this_three_months => 'Últimos 3 meses';

  @override
  String get log_detail_this_year => 'Este año';

  @override
  String log_metric_per_day_avg(String unit) {
    return '$unit por día (prom.)';
  }

  @override
  String get log_metric_goal_hit => 'Vas en objetivo.';

  @override
  String get log_metric_goal_miss => 'No has alcanzado tu objetivo.';

  @override
  String log_metric_left(String value) {
    return '$value restantes';
  }

  @override
  String get log_metric_below_range => 'Por debajo del rango';

  @override
  String get log_metric_no_data => 'Sin datos';

  @override
  String get log_metric_locked => 'Bloqueado';

  @override
  String get log_metric_history_locked => 'El historial completo es Pro';

  @override
  String get log_metric_detail_list_title => 'Este período';

  @override
  String get common_days => 'días';

  @override
  String get aha_prompt_title => 'Acabas de ahorrar 10 minutos';

  @override
  String get aha_prompt_subtitle =>
      'Imagina ahorrar este tiempo todos los días. Pásate a Pro para obtener escaneos de fotos ilimitados y un registro sin esfuerzo.';

  @override
  String get aha_prompt_btn => 'Pasar a Pro';

  @override
  String get macro_locked_title => 'Los macros son Pro';

  @override
  String get macro_locked_body =>
      'Desbloquea detalles de proteína, carbohidratos y grasas con SnapCal Pro.';

  @override
  String get macro_unlock_cta => 'Desbloquear macros';

  @override
  String get macro_locked_placeholder => 'Bloqueado';

  @override
  String get macro_unlock_card_title => 'Unlock your macro breakdown';

  @override
  String get macro_unlock_card_body =>
      'See protein, carbs and fat progress for every meal.';

  @override
  String get common_unlock => 'Desbloquear';

  @override
  String get scan_choice_title => 'Elige el tipo de escaneo';

  @override
  String get scan_choice_subtitle =>
      'Registra una comida desde una foto o escanea un alimento envasado.';

  @override
  String get scan_choice_food_title => 'Escanear comida';

  @override
  String get scan_choice_food_subtitle =>
      'Usa la cámara para nutrición instantánea con IA.';

  @override
  String get scan_choice_barcode_title => 'Escanear código';

  @override
  String get scan_choice_barcode_subtitle =>
      'Encuentra alimentos envasados por código de barras.';

  @override
  String get planner_empty_headline =>
      'Plan inteligente personalizado de 7 días';

  @override
  String get planner_empty_body =>
      'SnapCal crea comidas según tus calorías, macros, preferencias y compras.';

  @override
  String get planner_empty_benefit_adaptive => 'Guía adaptativa';

  @override
  String get planner_empty_benefit_macros => 'Macros equilibrados';

  @override
  String get planner_empty_benefit_grocery => 'Lista de compras';

  @override
  String get planner_adjust_preferences => 'Ajustar preferencias';

  @override
  String get planner_meals_unit => 'comidas';

  @override
  String get planner_items_unit => 'artículos';

  @override
  String get planner_avg_plan => 'Promedio';

  @override
  String get planner_protein_coverage => 'Proteína';

  @override
  String get planner_guidance_protein =>
      'Falta proteína; prioriza proteína en la próxima comida.';

  @override
  String get planner_guidance_light =>
      'Calorías ajustadas; mantén ligera la próxima comida.';

  @override
  String get planner_guidance_balanced =>
      'Vas bien; sigue las comidas planeadas.';

  @override
  String get planner_prep_time => 'Tiempo de preparación';

  @override
  String get planner_prep_quick => 'Rápido';

  @override
  String get planner_prep_balanced => 'Equilibrado';

  @override
  String get planner_prep_batch => 'Por lotes';

  @override
  String get planner_budget => 'Presupuesto';

  @override
  String get planner_budget_value => 'Económico';

  @override
  String get planner_budget_standard => 'Estándar';

  @override
  String get planner_budget_premium => 'Premium';

  @override
  String get planner_advanced_preferences => 'Preferencias avanzadas';

  @override
  String get planner_advanced_preferences_body =>
      'Alergias, gustos, equipo, porciones y días de entrenamiento quedan para una próxima mejora.';

  @override
  String get planner_swap_title => 'Cambiar comida';

  @override
  String get planner_swap_intent => 'Elige un objetivo';

  @override
  String get planner_swap_lower_calorie => 'Menos calorías';

  @override
  String get planner_swap_higher_protein => 'Más proteína';

  @override
  String get planner_swap_faster_prep => 'Más rápido';

  @override
  String get planner_swap_cheaper => 'Más barato';

  @override
  String get planner_swap_custom_note => 'Añadir nota opcional';

  @override
  String get planner_swap_note_hint => 'ej. pollo, ensalada, pasta...';

  @override
  String get planner_swap_generate => 'Generar cambio';

  @override
  String get planner_swap_with_note => 'Cambiar con nota';

  @override
  String get planner_swap_loading => 'Buscando alternativa...';

  @override
  String get planner_swap_success =>
      'Comida reemplazada con una alternativa práctica.';

  @override
  String get planner_grocery_ready => 'Lista de ya tengo';

  @override
  String get planner_already_have => 'Ya lo tienes';

  @override
  String get planner_rebalance_notice_light =>
      'Plan reajustado: las comidas restantes son más ligeras hoy.';

  @override
  String get planner_rebalance_notice_protein =>
      'Plan reajustado: las comidas restantes priorizan proteína.';

  @override
  String get planner_today_plan => 'Plan de hoy';

  @override
  String get planner_today_meals => 'Comidas de hoy';

  @override
  String get planner_planned_unit => 'planeadas';

  @override
  String get planner_planned_for_today => 'Planeado para hoy';

  @override
  String get planner_logged => 'Registrado';

  @override
  String get planner_upcoming => 'Próxima';

  @override
  String get planner_alert_next_protein =>
      'La próxima comida debe priorizar proteína';

  @override
  String get planner_alert_on_track => 'El plan va bien';

  @override
  String get planner_alert_follow_plan => 'Sigue la próxima comida planificada';

  @override
  String get planner_alert_fix_it => 'Ajustar';

  @override
  String get planner_week_complete_title => 'Este plan de comidas terminó';

  @override
  String get planner_generate_current_week => 'Generar plan de esta semana';

  @override
  String get settings_milliliters_unit => 'ml';

  @override
  String get log_customize_metrics_desc =>
      'Elige qué métricas aparecen en tu panel';

  @override
  String get log_metric_full_history_locked => 'Historial completo bloqueado';

  @override
  String get log_metric_full_history_upgrade =>
      'Actualiza a Pro para ver historial de más de 14 días';

  @override
  String planner_swap_replacing(Object food) {
    return 'Reemplazando: $food';
  }

  @override
  String planner_rebalance_notice_adjusted(Object count) {
    return 'Plan reajustado: $count \$_temp0 ajustadas para hoy.';
  }

  @override
  String planner_alert_protein_short(Object grams) {
    return 'Faltan ${grams}g de proteína hoy';
  }

  @override
  String planner_week_complete_body(Object date) {
    return 'Tu último plan terminó el $date. Genera un plan nuevo para la semana actual.';
  }

  @override
  String log_metric_goal_value(Object value) {
    return 'objetivo $value';
  }
}
