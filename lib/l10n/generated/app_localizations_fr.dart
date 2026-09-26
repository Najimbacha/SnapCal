// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get result_estimated_calories => 'Calories estimées';

  @override
  String get result_review_portions => 'Vérifiez les portions';

  @override
  String get result_portion_guidance =>
      'Touchez une quantité pour la modifier. Les estimations peuvent varier selon la portion et l’huile de cuisson.';

  @override
  String get result_volume_hint =>
      'Le volume est approximatif (1 g ≈ 1 ml). Vérifiez l’étiquette de la boisson.';

  @override
  String get result_set_volume => 'Définir le volume';

  @override
  String get result_scan_balance_pending => 'Vérification des scans restants…';

  @override
  String get result_scan_balance_unavailable => 'Solde de scans indisponible';

  @override
  String get result_health_score_hint =>
      'Guide nutritionnel Wazn, pas une évaluation médicale.';

  @override
  String get coach_allowance_used =>
      'Votre message gratuit a été utilisé. D’autres messages seront disponibles après la réinitialisation quotidienne.';

  @override
  String get planner_unlock_week => 'Débloquer la semaine complète';

  @override
  String get purchase_billed_yearly => 'Facturation annuelle';

  @override
  String get purchase_headline => 'Sachez quoi manger ensuite.';

  @override
  String get purchase_preview_title => 'Découvrez Wazn Pro en action';

  @override
  String get purchase_preview_advice => 'Prévoyez un dîner riche en protéines.';

  @override
  String get purchase_scan_detail => 'Notez vos repas sans limite mensuelle';

  @override
  String get purchase_planner_title => 'Des repas adaptés à vos objectifs';

  @override
  String get purchase_planner_detail => 'Une semaine et votre liste de courses';

  @override
  String get purchase_coach_title => 'Votre coach IA personnel';

  @override
  String get purchase_coach_detail => 'Des conseils nutritionnels au quotidien';

  @override
  String get home_dashboard_upgrade => 'Grammes, objectifs et prochain repas';

  @override
  String get home_dashboard_planner =>
      'Votre prochain repas, adapté à vos objectifs';

  @override
  String get home_dashboard_coach =>
      'Des conseils selon votre nutrition du jour';

  @override
  String get home_dashboard_open => 'Ouvrir';

  @override
  String get home_dashboard_ask => 'Demander';

  @override
  String get home_dashboard_liters => 'L';

  @override
  String get appTitle => 'Wazn';

  @override
  String get ads_label => 'PUBLICITÉ';

  @override
  String get ads_remove_prompt => 'Supprimer les pubs — Devenez Pro';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_skip => 'Passer';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_back => 'Retour';

  @override
  String get common_done => 'Terminé';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get common_offline_mode => 'Mode hors ligne';

  @override
  String get error_scan_failed =>
      'Échec du scan. Veuillez réessayer ou saisir manuellement.';

  @override
  String get error_barcode_not_found =>
      'Produit non trouvé. Veuillez essayer la saisie manuelle.';

  @override
  String get nav_home => 'Accueil';

  @override
  String get nav_log => 'Journal';

  @override
  String get nav_stats => 'Stats';

  @override
  String get nav_profile => 'Profil';

  @override
  String get home_greeting_morning => 'Bonjour';

  @override
  String get home_greeting_afternoon => 'Bon après-midi';

  @override
  String get home_greeting_evening => 'Bonsoir';

  @override
  String get home_calories_remaining => 'Calories restantes';

  @override
  String get home_calories_eaten => 'Consommées';

  @override
  String get home_calories_burned => 'Brûlées';

  @override
  String get home_water_title => 'Consommation d\'eau';

  @override
  String home_water_goal(int goal) {
    return 'Objectif : ${goal}ml';
  }

  @override
  String get home_start_walking => 'Commencez à marcher';

  @override
  String home_estimated_kcal(int count) {
    return '$count kcal estimées';
  }

  @override
  String home_active_kcal(int count) {
    return '$count kcal actives';
  }

  @override
  String get water_tap_to_open => 'Appuyez pour ouvrir';

  @override
  String water_goal_progress(int goal) {
    return 'sur $goal ml';
  }

  @override
  String get home_recent_meals => 'Repas récents';

  @override
  String get home_view_all => 'Voir tout';

  @override
  String home_streak_days(int count) {
    return 'Série de $count jours';
  }

  @override
  String get home_section_macros => 'Macros';

  @override
  String get home_section_actions => 'Actions rapides';

  @override
  String get home_action_log => 'Ouvrir le journal';

  @override
  String get home_action_reports => 'Voir les rapports';

  @override
  String get home_sync_prompt =>
      'Créez un compte pour synchroniser votre progression.';

  @override
  String get log_title => 'Journal alimentaire';

  @override
  String get log_subtitle => 'Suivez votre parcours nutritionnel';

  @override
  String get log_entries => 'ENTRÉES';

  @override
  String get log_total_kcal => 'KCAL TOTALES';

  @override
  String get log_history => 'HISTORIQUE DES REPAS';

  @override
  String get log_no_entries_today => 'Aucun journal aujourd\'hui';

  @override
  String get log_no_entries_history => 'Historique vide';

  @override
  String get log_track_prompt => 'Suivez vos repas pour les voir ici.';

  @override
  String get log_no_data_prompt => 'Il n\'y a pas de données pour ce jour.';

  @override
  String get log_return_today => 'Retour à aujourd\'hui';

  @override
  String get log_add_manually => 'Ajouter manuellement';

  @override
  String get log_daily_balance => 'Bilan quotidien';

  @override
  String get log_daily_health => 'Santé du jour';

  @override
  String get log_scan_meal => 'Scanner un repas';

  @override
  String log_calories_left(String value) {
    return '$value restantes';
  }

  @override
  String log_calories_over(String value) {
    return '$value au-dessus';
  }

  @override
  String log_add_meal_type(String meal) {
    return 'Ajouter $meal';
  }

  @override
  String log_protein_left_today(String value) {
    return 'Il reste $value g de protéines aujourd\'hui';
  }

  @override
  String get log_protein_goal_met_today =>
      'Objectif protéines atteint aujourd\'hui';

  @override
  String home_protein_goal_detail(int grams) {
    return '$grams g de protéines aujourd\'hui';
  }

  @override
  String log_removed_snackbar(String food) {
    return '$food supprimé';
  }

  @override
  String get assistant_title => 'Coach IA';

  @override
  String get assistant_status => 'Toujours actif';

  @override
  String get assistant_initial_prompt => 'Comment puis-je vous aider ?';

  @override
  String get assistant_initial_body =>
      'Votre coach Wazn est prêt à vous aider avec des recettes, des objectifs et des conseils en nutrition.';

  @override
  String get assistant_preparing =>
      'Préparation de votre parcours bien-être...';

  @override
  String get assistant_input_hint => 'Écrivez un message...';

  @override
  String get assistant_input_listening => 'Écoute en cours...';

  @override
  String get assistant_needs_connection =>
      'L\'assistant a besoin d\'une connexion.';

  @override
  String get assistant_clear_title => 'Effacer le chat ?';

  @override
  String get assistant_clear_body =>
      'Cela supprimera votre historique de conversation avec le coach.';

  @override
  String get assistant_clear_confirm => 'Effacer';

  @override
  String get assistant_starter_meal_title => 'Idées de repas';

  @override
  String get assistant_starter_meal_desc => 'Dîners riches en protéines';

  @override
  String get assistant_starter_cal_title => 'Point Calories';

  @override
  String get assistant_starter_cal_desc => 'Où en suis-je aujourd\'hui ?';

  @override
  String get assistant_starter_tips_title => 'Conseils';

  @override
  String get assistant_starter_tips_desc => 'Éviter les fringales nocturnes';

  @override
  String get assistant_starter_plans_title => 'Plans';

  @override
  String get assistant_starter_plans_desc => 'Créer un plan de 3 jours';

  @override
  String get premium_welcome => 'Bienvenue sur Wazn Pro ! 🎉';

  @override
  String get premium_restore_success => 'Achats restaurés ! 🎉';

  @override
  String get premium_restore_empty => 'Aucun achat précédent trouvé.';

  @override
  String get premium_restore_fail => 'Échec de la restauration des achats.';

  @override
  String get premium_plan_yearly => 'Annuel';

  @override
  String get premium_plan_6months => '6 Mois';

  @override
  String get premium_plan_3months => '3 Mois';

  @override
  String get premium_plan_2months => '2 Mois';

  @override
  String get premium_plan_monthly => 'Mensuel';

  @override
  String get premium_plan_weekly => 'Hebdomadaire';

  @override
  String get premium_plan_lifetime => 'À vie';

  @override
  String get premium_per_month => '/mois';

  @override
  String get premium_free_trial => 'essai gratuit';

  @override
  String get premium_start_trial => 'Démarrer l\'essai gratuit';

  @override
  String premium_start_plan(String plan, String price) {
    return 'Démarrer $plan — $price';
  }

  @override
  String get premium_loading => 'Chargement...';

  @override
  String get snap_align_food => 'Alignez les aliments dans le cadre';

  @override
  String get snap_analyzing => 'Analyse de votre repas...';

  @override
  String get snap_retake => 'Reprendre';

  @override
  String get snap_log_meal => 'Enregistrer ce repas';

  @override
  String get result_energy => 'Énergie';

  @override
  String get result_protein => 'Protéines';

  @override
  String get result_carbs => 'Glucides';

  @override
  String get result_fat => 'Lipides';

  @override
  String get result_portion => 'Taille de la portion';

  @override
  String get result_save_success => 'Repas enregistré avec succès !';

  @override
  String get result_health => 'SANTÉ';

  @override
  String get result_kcal => 'KCAL';

  @override
  String get result_calories => 'Calories';

  @override
  String get result_macronutrients => 'MACRONUTRIMENTS';

  @override
  String get result_logging_portion => 'PORTION D\'ENREGISTREMENT';

  @override
  String result_ai_estimate(int percent) {
    return '$percent% de l\'estimation IA';
  }

  @override
  String result_daily_goal_info(int percent) {
    return 'Ce repas représente $percent% de votre objectif quotidien.';
  }

  @override
  String get planner_title => 'Planificateur de Repas';

  @override
  String get planner_smart_title => 'Planificateur Intelligent';

  @override
  String get planner_empty_state => 'Aucun plan pour aujourd\'hui';

  @override
  String get planner_generate => 'Générer un Plan IA';

  @override
  String get planner_daily_goal => 'Objectif Quotidien';

  @override
  String get planner_tab_weekly => 'Plan Hebdomadaire';

  @override
  String get planner_tab_grocery => 'Liste de Courses';

  @override
  String get planner_day_mon => 'Lun';

  @override
  String get planner_day_tue => 'Mar';

  @override
  String get planner_day_wed => 'Mer';

  @override
  String get planner_day_thu => 'Jeu';

  @override
  String get planner_day_fri => 'Ven';

  @override
  String get planner_day_sat => 'Sam';

  @override
  String get planner_day_sun => 'Dim';

  @override
  String planner_no_meals(Object day) {
    return 'Aucun repas pour le $day';
  }

  @override
  String planner_regenerate_day(Object day) {
    return 'Régénérer le $day ?';
  }

  @override
  String get planner_grocery_empty => 'Aucune liste de courses pour le moment';

  @override
  String get planner_grocery_pro => 'La liste de courses est Pro';

  @override
  String get planner_share => 'Partager';

  @override
  String get planner_creating => 'Création de votre plan';

  @override
  String get planner_msg_calories => 'Calcul de vos besoins caloriques...';

  @override
  String get planner_msg_meals =>
      'Choix des meilleurs repas pour votre objectif...';

  @override
  String get planner_msg_macros => 'Équilibrage de vos macros...';

  @override
  String get planner_msg_grocery => 'Construction de votre liste de courses...';

  @override
  String get planner_msg_ready => 'Presque prêt...';

  @override
  String get error_offline => 'Hors ligne : analyse IA indisponible';

  @override
  String get error_camera => 'Caméra indisponible';

  @override
  String get error_image_unsupported =>
      'Ce format d\'image n\'est pas pris en charge';

  @override
  String get error_generic => 'Un problème est survenu';

  @override
  String get sync_title => 'Synchro Cloud';

  @override
  String get sync_subtitle =>
      'Gardez vos données de santé en sécurité sur tous vos appareils avec un compte.';

  @override
  String get sync_benefit_devices => 'Synchro sur tous vos appareils';

  @override
  String get sync_benefit_progress => 'Ne perdez jamais votre progression';

  @override
  String get sync_benefit_offline => 'Fonctionne hors ligne, synchro en ligne';

  @override
  String get sync_benefit_secure => 'Vos données sont chiffrées et sécurisées';

  @override
  String get sync_google => 'Continuer avec Google';

  @override
  String get sync_facebook => 'Continuer avec Facebook';

  @override
  String get sync_email => 'Continuer avec l\'e-mail';

  @override
  String get sync_skip => 'Ignorer pour l\'instant';

  @override
  String get splash_calorie_tracker => 'Suivi des calories';

  @override
  String get splash_tagline => 'Photographiez. Suivez. Progressez.';

  @override
  String get notif_breakfast_title => 'Rappel du Petit-déjeuner';

  @override
  String get notif_breakfast_body =>
      'C\'est l\'heure d\'enregistrer votre petit-déjeuner sain !';

  @override
  String get notif_lunch_title => 'Rappel du Déjeuner';

  @override
  String get notif_lunch_body => 'N\'oubliez pas de suivre votre déjeuner.';

  @override
  String get notif_dinner_title => 'Rappel du Dîner';

  @override
  String get notif_dinner_body =>
      'Finissez la journée en beauté — enregistrez votre dîner dès maintenant.';

  @override
  String get notif_meal_reminders_channel => 'Rappels de repas';

  @override
  String get notif_prompt_title => 'Un rappel à l’heure des repas';

  @override
  String get notif_prompt_body =>
      'Wazn peut vous rappeler d’enregistrer le petit-déjeuner, le déjeuner et le dîner. Vous pouvez modifier cela à tout moment dans les réglages.';

  @override
  String get notif_prompt_allow => 'Activer les rappels';

  @override
  String get notif_prompt_later => 'Pas maintenant';

  @override
  String get notif_blocked_title =>
      'Les notifications de Wazn sont désactivées';

  @override
  String get notif_blocked_body =>
      'Votre téléphone les bloque, les rappels ne peuvent donc pas vous parvenir. Touchez pour les activer.';

  @override
  String get notif_food_reminders_channel => 'Rappels de scan des repas';

  @override
  String get notif_food_reminders_channel_description =>
      'Des rappels pour scanner vos repas';

  @override
  String get notif_updates_channel => 'Actualités de Wazn';

  @override
  String get notif_updates_channel_description =>
      'Nouveautés et mises à jour de Wazn';

  @override
  String get notif_meal_reminders_channel_description =>
      'Rappels pour suivre votre nutrition quotidienne.';

  @override
  String get notif_daily_motivation_channel => 'Motivation quotidienne';

  @override
  String get notif_daily_motivation_channel_description =>
      'Motivation nutritionnelle quotidienne et douce de Wazn.';

  @override
  String get notif_motivation_1_title => 'Les petits pas comptent';

  @override
  String get notif_motivation_1_body =>
      'Enregistrez votre premier repas quand vous êtes prêt.';

  @override
  String get notif_motivation_2_title => 'Aujourd’hui commence simple';

  @override
  String get notif_motivation_2_body =>
      'Choisissez un repas qui soutient votre objectif.';

  @override
  String get notif_motivation_3_title => 'Un bon choix';

  @override
  String get notif_motivation_3_body =>
      'Commencez par des protéines, de l’eau ou un suivi rapide.';

  @override
  String get notif_motivation_4_title => 'Pas besoin d’être parfait';

  @override
  String get notif_motivation_4_body =>
      'Observez simplement ce que vous mangez aujourd’hui.';

  @override
  String get notif_motivation_5_title => 'Du carburant d’abord';

  @override
  String get notif_motivation_5_body =>
      'Donnez quelque chose d’utile à votre corps aujourd’hui.';

  @override
  String get notif_motivation_6_title => 'Rendez ça facile';

  @override
  String get notif_motivation_6_body =>
      'Suivez un repas. C’est déjà un bon début.';

  @override
  String get notif_motivation_7_title => 'Construisez bien la journée';

  @override
  String get notif_motivation_7_body =>
      'Un premier repas équilibré facilite le choix suivant.';

  @override
  String get notif_motivation_8_title => 'Votre santé est quotidienne';

  @override
  String get notif_motivation_8_body =>
      'Un petit suivi vous aide à garder le contrôle.';

  @override
  String get auth_title => 'Votre parcours\ncommence ici';

  @override
  String get auth_subtitle =>
      'Photographiez, suivez et maîtrisez votre nutrition en quelques secondes.';

  @override
  String get auth_divider_email => 'Ou utilisez votre e-mail';

  @override
  String get auth_hint_email => 'Adresse e-mail';

  @override
  String get auth_hint_password => 'Mot de passe';

  @override
  String get auth_btn_signup => 'Créer mon compte';

  @override
  String get auth_btn_signin => 'Se connecter par e-mail';

  @override
  String get auth_footer_member => 'Déjà membre ? ';

  @override
  String get auth_footer_new => 'Nouveau sur Wazn ? ';

  @override
  String get auth_action_signin => 'Se connecter';

  @override
  String get auth_action_join => 'Rejoignez-nous';

  @override
  String get auth_msg_success => 'Connexion réussie !';

  @override
  String auth_msg_welcome(String name) {
    return 'Bon retour parmi nous, $name !';
  }

  @override
  String get result_meal_breakfast => 'Petit-déjeuner';

  @override
  String get result_meal_lunch => 'Déjeuner';

  @override
  String get result_meal_dinner => 'Dîner';

  @override
  String get result_meal_snack => 'Collation';

  @override
  String get result_macro_power => 'FORCE';

  @override
  String get result_macro_energy => 'ÉNERGIE';

  @override
  String get result_macro_lean => 'LÉGER';

  @override
  String get common_hero => 'HÉROS';

  @override
  String get notif_goal_calories_title => 'Objectif atteint ! 🚀';

  @override
  String notif_goal_calories_body(Object goal) {
    return 'Vous avez atteint votre objectif quotidien de $goal kcal !';
  }

  @override
  String get notif_goal_protein_title => 'Objectif protéines rempli ! 💪';

  @override
  String notif_goal_protein_body(Object goal) {
    return 'Beau travail ! Vous avez atteint votre cible de ${goal}g de protéines.';
  }

  @override
  String get notif_goal_alerts_channel => 'Alertes d’objectifs';

  @override
  String get notif_goal_alerts_channel_description =>
      'Alertes lorsque vous atteignez vos objectifs nutritionnels.';

  @override
  String get common_confirm => 'Confirmer';

  @override
  String get common_save_progress => 'Enregistrer les progrès';

  @override
  String get common_delete_permanently => 'Supprimer définitivement';

  @override
  String get common_try_again => 'Réessayer';

  @override
  String get common_try_reload => 'Recharger';

  @override
  String get common_sign_out => 'Se déconnecter';

  @override
  String get common_sign_out_confirm =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get common_delete_account => 'Supprimer le compte ?';

  @override
  String get common_delete_account_confirm =>
      'Cette action est irréversible. Toutes vos données seront perdues.';

  @override
  String get settings_save_name => 'Enregistrer le nom';

  @override
  String get settings_log_weight_first =>
      'Enregistrez votre poids d\'abord pour recalculer.';

  @override
  String get settings_complete_profile_first =>
      'Complétez votre profil d\'abord (âge, sexe, taille, objectif).';

  @override
  String get settings_age => 'Âge';

  @override
  String get settings_gender => 'Genre';

  @override
  String get settings_units => 'Unités';

  @override
  String get settings_weight_unit => 'Unité de poids';

  @override
  String get settings_height_unit => 'Unité de taille';

  @override
  String get settings_breakfast_time => 'Rappel petit-déjeuner';

  @override
  String get settings_lunch_time => 'Rappel déjeuner';

  @override
  String get settings_dinner_time => 'Rappel dîner';

  @override
  String get planner_upgrade_pro => 'Passer à Pro';

  @override
  String get planner_regenerate => 'Régénérer';

  @override
  String get planner_meal_preferences => 'Préférences de repas';

  @override
  String get planner_meals_per_day => 'Repas par jour';

  @override
  String get planner_dietary_restriction => 'Restriction alimentaire';

  @override
  String get planner_cuisine_style => 'Style de cuisine';

  @override
  String get planner_generate_plan => 'Générer mon plan';

  @override
  String get assistant_mic_permission =>
      'L\'autorisation du micro est requise pour la commande vocale.';

  @override
  String get assistant_added_to_diary => 'Ajouté à votre journal ! 🍎';

  @override
  String assistant_plan_updated(String key, String value) {
    return 'Plan mis à jour : $key est maintenant $value';
  }

  @override
  String get water_add_water => 'Ajouter de l\'eau';

  @override
  String get water_add => 'Ajouter';

  @override
  String get water_remove => 'Retirer';

  @override
  String get water_hydration => 'Hydratation';

  @override
  String water_add_amount(int count) {
    return 'Ajouter $count ml';
  }

  @override
  String water_remaining(int count) {
    return '$count ml restants';
  }

  @override
  String get water_goal_complete => 'Objectif quotidien atteint';

  @override
  String get water_reset => 'Réinitialiser';

  @override
  String get water_undo => 'Annuler';

  @override
  String get water_reset_title => 'Réinitialiser l\'eau ?';

  @override
  String get water_reset_body =>
      'Effacer toute l\'eau enregistrée aujourd\'hui.';

  @override
  String get water_tracker => 'Suivi de l\'hydratation';

  @override
  String water_reached(int amount, int goal) {
    return '$amount sur $goal ml atteints';
  }

  @override
  String get water_custom => 'Personnalisé';

  @override
  String get water_enter_amount => 'Entrez la quantité';

  @override
  String get progress_tap_to_snap => 'Appuyez pour capturer';

  @override
  String get progress_compare_previous => 'Comparer avec le précédent';

  @override
  String get log_delete_meal_title => 'Supprimer le repas ?';

  @override
  String get log_delete_meal_body =>
      'Cela supprimera définitivement ce repas de votre journal.';

  @override
  String get settings_title => 'Paramètres';

  @override
  String get settings_display_name => 'Nom d\'affichage';

  @override
  String get settings_how_to_call => 'Comment devrions-nous vous appeler ?';

  @override
  String settings_enter_value(String title) {
    return 'Entrez votre $title ci-dessous';
  }

  @override
  String get settings_core_config => 'Vous';

  @override
  String get settings_data_security => 'Vos données';

  @override
  String get settings_information => 'À propos';

  @override
  String get settings_body_profile => 'Profil corporel';

  @override
  String get settings_body_profile_sub =>
      'Mettez à jour vos stats et objectifs';

  @override
  String get settings_nutrition_goals => 'Objectifs nutritionnels';

  @override
  String get settings_nutrition_goals_sub =>
      'Cibles quotidiennes calories et macros';

  @override
  String get settings_preferences => 'Préférences';

  @override
  String get settings_preferences_sub => 'Thème et paramètres de notification';

  @override
  String get settings_account => 'Compte';

  @override
  String get settings_account_sub => 'Abonnement et sécurité du profil';

  @override
  String get settings_data_sync => 'Données et synchronisation';

  @override
  String get settings_data_sync_sub => 'Options d\'exportation et sauvegarde';

  @override
  String get settings_about => 'À propos';

  @override
  String get about_email_us => 'Écrivez-nous';

  @override
  String get about_instagram_desc => 'Astuces, recettes et communauté';

  @override
  String get about_facebook_desc => 'Suivez notre page';

  @override
  String get settings_about_sub => 'Conditions, confidentialité et infos';

  @override
  String get report_title => 'Rapports';

  @override
  String get report_subtitle => 'Suivez votre succès à long terme';

  @override
  String get report_tab_nutrition => 'Nutrition';

  @override
  String get report_tab_body => 'Corps';

  @override
  String get report_weekly_review => 'Revue Hebdomadaire';

  @override
  String get report_monthly_audit => 'Audit mensuel';

  @override
  String get report_failed =>
      'Impossible de créer votre rapport. Veuillez réessayer.';

  @override
  String get settings_restore_desc =>
      'Déjà payé ? Récupérez Pro sur ce téléphone';

  @override
  String get settings_delete_failed =>
      'Impossible de supprimer votre compte. Vérifiez votre connexion et réessayez.';

  @override
  String get settings_deleting_account => 'Suppression de votre compte…';

  @override
  String get settings_account_deleted =>
      'Votre compte et vos données ont été supprimés.';

  @override
  String get settings_delete_subscription_note =>
      'Cela n’annule pas votre abonnement Wazn Pro. Annulez-le dans Google Play pour ne plus être facturé.';

  @override
  String get settings_name_failed =>
      'Impossible de modifier votre nom. Veuillez réessayer.';

  @override
  String get paywall_welcome => 'Bienvenue sur Wazn Pro ! 🎉';

  @override
  String get progress_log_progress => 'Enregistrer le progrès';

  @override
  String get progress_take_photos_desc =>
      'Prenez des photos pour suivre votre parcours.';

  @override
  String get progress_front_view => 'Vue de face';

  @override
  String get progress_side_view => 'Vue de côté';

  @override
  String get progress_saving => 'Enregistrement...';

  @override
  String get progress_save_progress => 'Enregistrer le progrès';

  @override
  String get progress_comparison => 'Comparaison';

  @override
  String progress_weight_diff(String diff) {
    return '$diff kg de différence';
  }

  @override
  String get progress_before => 'Avant';

  @override
  String get progress_after => 'Après';

  @override
  String get progress_missing_photos =>
      'Photos manquantes pour la comparaison.';

  @override
  String get progress_front => 'Face';

  @override
  String get progress_side => 'Profil';

  @override
  String get progress_failed_camera => 'Échec de l\'ouverture de la caméra.';

  @override
  String get assistant_attached_image => 'Image jointe';

  @override
  String get home_body_stats => 'Stats corps';

  @override
  String get log_edit_meal => 'Modifier le repas';

  @override
  String get log_log_new_meal => 'Nouveau repas';

  @override
  String get log_food_name => 'Nom de l\'aliment';

  @override
  String get log_portion_desc => 'Description de la portion';

  @override
  String get log_calories_kcal => 'Calories (kcal)';

  @override
  String get log_save_entry => 'Enregistrer';

  @override
  String get log_delete_entry => 'Supprimer l\'entrée';

  @override
  String get log_food_hint => 'ex. Toast à l\'avocat';

  @override
  String get log_protein_g => 'Protéines (g)';

  @override
  String get log_carbs_g => 'Glucides (g)';

  @override
  String get log_fat_g => 'Lipides (g)';

  @override
  String get common_keep_it => 'Garder';

  @override
  String get planner_target => 'Objectif';

  @override
  String get planner_setup_desc => 'Configuration rapide avant votre plan';

  @override
  String get planner_ai_disclaimer =>
      'Ce plan est généré par IA à titre indicatif seulement.';

  @override
  String get planner_restriction_none => 'Aucune';

  @override
  String get planner_restriction_vegetarian => 'Végétarien';

  @override
  String get planner_restriction_vegan => 'Végétalien';

  @override
  String get planner_restriction_gluten_free => 'Sans gluten';

  @override
  String get planner_restriction_keto => 'Cétogène';

  @override
  String get planner_restriction_halal => 'Halal';

  @override
  String get planner_cuisine_international => 'Internationale';

  @override
  String get planner_cuisine_south_asian => 'Asie du Sud';

  @override
  String get planner_cuisine_mediterranean => 'Méditerranéenne';

  @override
  String get planner_cuisine_east_asian => 'Asie de l\'Est';

  @override
  String get planner_cuisine_american => 'Américaine';

  @override
  String get planner_cuisine_middle_eastern => 'Moyen-Orientale';

  @override
  String get snap_offline_error =>
      'L\'analyse par IA nécessite une connexion internet.';

  @override
  String get home_metric_goal => 'Objectif';

  @override
  String get home_metric_meals => 'Repas';

  @override
  String get home_metric_goal_hint => 'Cible quotidienne';

  @override
  String get home_metric_meals_hint => 'Enregistrés aujourd\'hui';

  @override
  String get home_no_meals_title => 'Aucun repas enregistré';

  @override
  String get home_no_meals_body => 'Commencez par une photo rapide.';

  @override
  String get home_first_meal_cta_title => 'Scannez un repas pour commencer';

  @override
  String get home_first_meal_cta_body =>
      'Utilisez l\'appareil photo pour enregistrer calories et macros automatiquement.';

  @override
  String get first_meal_guide_title => 'Commencez par une photo du repas';

  @override
  String get first_meal_guide_body =>
      'Photographiez le repas, vérifiez l\'estimation, puis ajoutez-le au journal.';

  @override
  String get first_meal_guide_action => 'Scanner un repas';

  @override
  String get first_meal_guide_dismiss => 'Fermer le guide du premier repas';

  @override
  String get home_section_macros_today => 'Macros du jour';

  @override
  String get home_eaten_progress => 'CONSOMMÉ';

  @override
  String get home_steps_today => 'pas aujourd\'hui';

  @override
  String get home_default_name => 'Ami';

  @override
  String get log_portion_hint => 'ex. 1 bol, 200g, 1 tranche';

  @override
  String get log_unknown_food => 'Aliment inconnu';

  @override
  String get home_goal_reached => 'OBJECTIF';

  @override
  String get home_completed => 'TERMINÉ';

  @override
  String get home_kcal_left => 'kcal restantes';

  @override
  String get home_kcal_over => 'kcal de trop aujourd\'hui';

  @override
  String get home_todays_meals => 'Repas du jour';

  @override
  String get home_open_log => 'Ouvrir le journal';

  @override
  String get home_unlock_meal_plan_title =>
      'Débloquez votre plan de repas complet';

  @override
  String get home_unlock_meal_plan_subtitle =>
      'Déjeuner · Dîner · Suggestions intelligentes';

  @override
  String get assistant_typing => 'Le coach écrit...';

  @override
  String get assistant_retry => 'Réessayer';

  @override
  String get assistant_speech_not_available =>
      'Reconnaissance vocale indisponible';

  @override
  String get paywall_pro_plan => 'PLAN PRO';

  @override
  String get paywall_unlock_unlimited => 'Déblocage Illimité';

  @override
  String get paywall_subtitle => 'Découvrez toute la puissance du coaching IA.';

  @override
  String get paywall_feature_unlimited => 'Illimité';

  @override
  String get paywall_feature_scans => 'Scans Quotidiens';

  @override
  String get paywall_feature_smart => 'Intelligent';

  @override
  String get paywall_feature_plans => 'Plans de Repas';

  @override
  String get paywall_feature_coach => 'Coach IA';

  @override
  String get paywall_feature_advice => 'Conseils Proactifs';

  @override
  String get paywall_feature_ads => 'Sans Pub';

  @override
  String get paywall_feature_no_ads => 'Zéro Interruption';

  @override
  String get paywall_best_value => 'MEILLEUR PRIX';

  @override
  String get paywall_restore => 'Restaurer les achats';

  @override
  String get paywall_purchase_failed => 'Échec de l\'achat. Réessayez.';

  @override
  String paywall_save_percent(Object percent) {
    return 'ÉCONOMISEZ $percent%';
  }

  @override
  String get paywall_trial_title => 'Comment fonctionne votre essai';

  @override
  String get paywall_trial_today => 'Aujourd\'hui';

  @override
  String get paywall_trial_today_desc =>
      'Accès complet à toutes les fonctions Pro.';

  @override
  String paywall_trial_end(Object day) {
    return 'Jour $day';
  }

  @override
  String get paywall_trial_end_desc =>
      'Le prélèvement a lieu. Annulez avant pour éviter.';

  @override
  String get paywall_referral_title => 'Voulez-vous la version gratuite ?';

  @override
  String get paywall_referral_subtitle =>
      'Invitez des amis pour des scans bonus.';

  @override
  String paywall_then(Object price) {
    return 'Ensuite $price';
  }

  @override
  String get settings_select_language => 'Choisir la Langue';

  @override
  String get settings_language_desc => 'Choisissez votre langue d\'interface';

  @override
  String get settings_lang_en_desc => 'Langue par défaut';

  @override
  String get settings_lang_ar_desc => 'Arabe (Support RTL)';

  @override
  String get settings_lang_es_desc => 'Espagnol';

  @override
  String get settings_lang_fr_desc => 'Français';

  @override
  String get settings_appearance => 'Apparence';

  @override
  String get settings_theme_system => 'Système';

  @override
  String get settings_theme_light => 'Clair';

  @override
  String get settings_theme_dark => 'Sombre';

  @override
  String get settings_data_sync_title => 'Données & Synchro';

  @override
  String get settings_export_data => 'Exporter les données';

  @override
  String get settings_export_desc => 'Téléchargez vos repas et métriques';

  @override
  String get settings_cloud_sync_desc =>
      'Connectez-vous pour sauvegarder vos données';

  @override
  String get settings_about_title => 'À propos';

  @override
  String get settings_privacy => 'Politique de confidentialité';

  @override
  String get settings_privacy_desc => 'Gestion de vos données';

  @override
  String get settings_terms => 'Conditions d\'utilisation';

  @override
  String get settings_licenses => 'Licences open source';

  @override
  String get settings_licenses_desc =>
      'Les logiciels sur lesquels Wazn est construit';

  @override
  String get settings_terms_desc => 'Conditions générales';

  @override
  String get settings_about_snapcal => 'À propos de Wazn';

  @override
  String get settings_upgrade_pro => 'Passer à Pro';

  @override
  String get settings_upgrade_desc => 'Scans illimités & coach IA';

  @override
  String get planner_free_limit_body => 'Les gratuits ne voient que Lun & Mar.';

  @override
  String get planner_grocery_empty_body =>
      'Générez d\'abord un plan hebdomadaire et votre liste de courses apparaîtra ici.';

  @override
  String get planner_grocery_pro_body => 'Passez à Pro pour gérer votre liste.';

  @override
  String planner_regenerate_body(String day) {
    return 'Ceci remplacera les repas du $day.';
  }

  @override
  String get planner_setup_body =>
      'Dites-nous vos objectifs et nous créerons un plan de repas personnalisé de 7 jours pour vous.';

  @override
  String get planner_no_meals_body => 'Essayez de régénérer ce jour.';

  @override
  String get report_weekly => 'Hebdomadaire';

  @override
  String get report_monthly => 'Mensuel';

  @override
  String get onboarding_get_started => 'Commencer';

  @override
  String get onboarding_continue => 'Continuer';

  @override
  String get onboarding_male => 'Homme';

  @override
  String get onboarding_female => 'Femme';

  @override
  String get planner_meal => 'Repas';

  @override
  String get planner_ingredients => 'Ingrédients';

  @override
  String get common_mins => 'min';

  @override
  String planner_kcal_total(int goal) {
    return '/ $goal kcal';
  }

  @override
  String planner_kcal_over(int delta) {
    return '+$delta au-dessus';
  }

  @override
  String planner_kcal_under(int delta) {
    return '$delta en dessous';
  }

  @override
  String get planner_kcal_on_target => 'Sur la cible';

  @override
  String get snap_gallery => 'Galerie';

  @override
  String get snap_barcode => 'Code-barres';

  @override
  String get snap_pro_unlimited => '∞ Pro';

  @override
  String get snap_bento_plate => 'Plateau Bento';

  @override
  String snap_items_detected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments détectés',
      one: 'Un élément détecté',
      zero: 'Aucun élément détecté',
    );
    return '$_temp0 sur votre plateau.';
  }

  @override
  String get snap_total_meal => 'TOTAL REPAS';

  @override
  String snap_items_selected(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments sélectionnés',
      one: 'Un élément sélectionné',
      zero: 'Aucun élément sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get settings_body_profile_title => 'Profil corporel';

  @override
  String get settings_body_profile_desc =>
      'Gérez vos métriques physiques et objectifs.';

  @override
  String get settings_display_name_label => 'Nom d\'affichage';

  @override
  String get settings_set_name => 'Définir le nom';

  @override
  String get settings_current_weight => 'Poids actuel';

  @override
  String get settings_set_weight => 'Définir le poids';

  @override
  String get settings_height => 'Taille';

  @override
  String get settings_set_height => 'Définir la taille';

  @override
  String get settings_target_weight => 'Poids cible';

  @override
  String get settings_set_target => 'Définir l\'objectif';

  @override
  String get settings_nutrition_goals_title => 'Objectifs nutritionnels';

  @override
  String get settings_daily_calories => 'Calories quotidiennes';

  @override
  String get settings_protein => 'Protéines';

  @override
  String get settings_carbs => 'Glucides';

  @override
  String get settings_fat => 'Lipides';

  @override
  String get settings_optimize_btn => 'Optimiser mon plan nutritionnel';

  @override
  String get settings_optimizing => 'Optimisation du plan...';

  @override
  String get settings_recalculate_query =>
      'Je viens d\'optimiser mon plan nutritionnel. Veuillez expliquer pourquoi ces calories et macros spécifiques ont été choisis pour moi en fonction de mon profil.';

  @override
  String get settings_guest_account => 'Compte invité';

  @override
  String get settings_sign_in => 'Se connecter';

  @override
  String get settings_member => 'Membre Wazn';

  @override
  String get settings_auth_cta => 'S\'inscrire ou Se connecter';

  @override
  String get settings_preferences_title => 'Préférences';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_meal_reminders => 'Rappels de repas';

  @override
  String get settings_daily_motivation => 'Motivation quotidienne';

  @override
  String get settings_food_reminders => 'Rappels de scan des aliments';

  @override
  String get settings_food_reminders_subtitle =>
      'Recevez des rappels pour scanner vos repas';

  @override
  String get settings_language => 'Langue';

  @override
  String get settings_account_title => 'Compte';

  @override
  String get settings_subscription => 'Abonnement';

  @override
  String get settings_pro_active => 'Pro actif';

  @override
  String get settings_manage_plan => 'Gérer l\'abonnement';

  @override
  String get settings_create_account => 'Créer un compte';

  @override
  String get settings_sign_out_desc => 'Quitter cette session';

  @override
  String get settings_sync_data_desc => 'Synchronisez vos données';

  @override
  String get settings_about_app => 'À propos de Wazn';

  @override
  String get settings_legalese => '© 2026 Wazn. Tous droits réservés.';

  @override
  String get error_connection_title => 'Problème de connexion';

  @override
  String get error_connection_body =>
      'Impossible d\'initialiser Wazn. Veuillez vérifier vos données ou le Wi-Fi.';

  @override
  String get error_unexpected_title => 'Quelque chose s\'est mal passé';

  @override
  String get error_unexpected_body =>
      'Nous avons rencontré une erreur inattendue. Notre équipe a été informée et nous travaillons à la résoudre.';

  @override
  String get report_guest_user => 'Cher utilisateur';

  @override
  String get report_avg_calories => 'Calories moyennes';

  @override
  String get report_consistency => 'Cohérence';

  @override
  String get report_calorie_trend => 'Tendance des calories';

  @override
  String get report_macro_dist => 'Répartition des macros';

  @override
  String get report_macro_protein => 'Protéines';

  @override
  String get report_macro_carbs => 'Glucides';

  @override
  String get report_macro_fat => 'Lipides';

  @override
  String get report_no_weight_title => 'Pas encore de relevés de poids';

  @override
  String get report_no_meals_title =>
      'Aucun repas enregistré sur cette période';

  @override
  String get report_no_meals_body =>
      'Enregistrez vos repas : vos moyennes, votre tendance de calories et vos macros apparaîtront ici.';

  @override
  String get progress_no_photos_title => 'Pas encore de photos de progression';

  @override
  String get report_no_weight_body =>
      'Ajoutez votre premier relevé pour que votre tendance corporelle puisse commencer.';

  @override
  String get report_log_weight => 'Enregistrer le poids';

  @override
  String get report_weight_current => 'Actuel';

  @override
  String get report_weight_change => 'Changement';

  @override
  String get report_progress_timeline => 'Chronologie des progrès';

  @override
  String get report_progress_gallery =>
      'Galerie visuelle de transformation corporelle';

  @override
  String get report_weight_analytics => 'Analyse du poids';

  @override
  String get report_recent_history => 'Historique récent';

  @override
  String report_body_fat_pct(String percent) {
    return '$percent% de graisse';
  }

  @override
  String get weight_hint => 'Poids';

  @override
  String get body_fat_hint => 'Graisse corporelle (optionnel)';

  @override
  String get snap_scan_barcode => 'Scanner le code-barres';

  @override
  String get snap_barcode_hint => 'Placez le code-barres dans le cadre.';

  @override
  String get snap_torch => 'Lampe';

  @override
  String get snap_flip => 'Retourner';

  @override
  String get settings_health_sync => 'Sync santé';

  @override
  String get settings_health_sync_sub =>
      'Synchroniser les pas et calories brûlées';

  @override
  String get home_metric_activity => 'Activité';

  @override
  String get home_metric_activity_sync => 'Sync';

  @override
  String get home_metric_activity_enable => 'Activer Santé';

  @override
  String get progress_generate_video => 'Générer la vidéo du parcours';

  @override
  String get progress_video_failed =>
      'Échec de la génération de la vidéo. Réessayez.';

  @override
  String get progress_video_min_photos =>
      'Prenez au moins 2 photos de progression d\'abord !';

  @override
  String get progress_video_share_text =>
      'Mon parcours de transformation Wazn ! 🚀';

  @override
  String get widget_status_on_track => 'Sur la bonne voie';

  @override
  String get widget_status_over_goal => 'Objectif dépassé';

  @override
  String get widget_status_almost_there => 'Presque arrivé';

  @override
  String get feature_insights_title => 'Bilan Hebdo';

  @override
  String get feature_insights_desc => 'Votre semaine en revue';

  @override
  String feature_insights_avg_cal(String cal) {
    return 'Moy $cal kcal/jour';
  }

  @override
  String feature_insights_on_track(String days) {
    return '$days jours sur la bonne voie';
  }

  @override
  String get feature_insights_generating => 'Génération des conseils...';

  @override
  String get feature_insights_share => 'Partager ma semaine';

  @override
  String get feature_templates_title => 'Mes Routines';

  @override
  String get feature_templates_empty =>
      'Enregistrez votre première routine ! Enregistrez un repas, puis appuyez sur \'Enregistrer comme routine\'.';

  @override
  String get feature_templates_save_prompt => 'Enregistrer comme routine ?';

  @override
  String get feature_templates_name_hint => 'ex: Petit-déjeuner';

  @override
  String get feature_templates_save_btn => 'Enregistrer la routine';

  @override
  String get feature_templates_update_btn => 'Mettre à jour la routine';

  @override
  String get feature_templates_limit_reached =>
      'Limite gratuite atteinte. Passez à la version Pro pour des routines illimitées !';

  @override
  String get feature_templates_logged => 'Routine enregistrée avec succès !';

  @override
  String get settings_your_journey => 'Votre parcours';

  @override
  String get settings_progress => 'Progression';

  @override
  String get settings_progress_empty => 'Aucune pesée pour l\'instant';

  @override
  String settings_achievements_earned(String count, String total) {
    return '$count sur $total obtenus';
  }

  @override
  String progress_change_since(String change, String date) {
    return '$change depuis le $date';
  }

  @override
  String achievement_to_go(String count) {
    return 'Plus que $count';
  }

  @override
  String achievement_earned_on(String date) {
    return 'Obtenu le $date';
  }

  @override
  String get feature_achievements_title => 'Succès';

  @override
  String feature_achievements_unlocked(String count) {
    return '$count débloqués';
  }

  @override
  String get achievement_first_flame => 'Première Flamme';

  @override
  String get achievement_first_flame_desc => 'Enregistrez votre premier repas';

  @override
  String get achievement_consistency_king => 'Roi de la Constance';

  @override
  String get achievement_consistency_king_desc => 'Série de 7 jours';

  @override
  String get achievement_iron_will => 'Volonté de Fer';

  @override
  String get achievement_iron_will_desc => 'Série de 30 jours';

  @override
  String get achievement_unstoppable => 'Inarrêtable';

  @override
  String get achievement_unstoppable_desc => 'Série de 100 jours';

  @override
  String get achievement_bullseye => 'Dans le Mille';

  @override
  String get achievement_bullseye_desc =>
      'Atteignez exactement l\'objectif de calories';

  @override
  String get achievement_precision_pro => 'Pro de la Précision';

  @override
  String get achievement_precision_pro_desc =>
      'Objectif de calories atteint 7 jours de suite';

  @override
  String get achievement_macro_master => 'Maître des Macros';

  @override
  String get achievement_macro_master_desc =>
      'Atteignez tous les macros en un jour';

  @override
  String get achievement_perfect_week => 'Semaine Parfaite';

  @override
  String get achievement_perfect_week_desc =>
      'Atteignez tous les objectifs pendant 7 jours';

  @override
  String get achievement_first_sip => 'Première Gorgée';

  @override
  String get achievement_first_sip_desc =>
      'Enregistrez de l\'eau pour la première fois';

  @override
  String get achievement_hydration_hero => 'Héros de l\'Hydratation';

  @override
  String get achievement_hydration_hero_desc =>
      'Objectif d\'eau atteint 30 jours';

  @override
  String get achievement_ocean_mode => 'Mode Océan';

  @override
  String get achievement_ocean_mode_desc => 'Objectif d\'eau atteint 100 jours';

  @override
  String get achievement_first_snap => 'Premier Snap';

  @override
  String get achievement_first_snap_desc =>
      'Enregistrez 1 repas via l\'appareil photo';

  @override
  String get achievement_snap_master => 'Maître du Snap';

  @override
  String get achievement_snap_master_desc => 'Enregistrez 100 repas';

  @override
  String get achievement_snap_legend => 'Légende du Snap';

  @override
  String get achievement_snap_legend_desc => 'Enregistrez 500 repas';

  @override
  String get achievement_first_checkin => 'Premier Point';

  @override
  String get achievement_first_checkin_desc =>
      'Enregistrez une première photo de corps';

  @override
  String get achievement_transformation => 'Transformation';

  @override
  String get achievement_transformation_desc =>
      'Enregistrez 10 photos de corps';

  @override
  String get achievement_journey_video => 'Vidéo du Parcours';

  @override
  String get achievement_journey_video_desc =>
      'Générez une vidéo de transformation';

  @override
  String get feature_achievements_unlocked_title => 'Succès Débloqué !';

  @override
  String get common_continue => 'Continuer';

  @override
  String get feature_insights_subtitle =>
      'Votre résumé nutritionnel hebdomadaire par IA est prêt !';

  @override
  String get feature_insights_share_text =>
      'Découvrez mon résumé nutritionnel hebdomadaire de Wazn ! 📊';

  @override
  String get settings_guest_title => 'Protégez vos progrès';

  @override
  String get settings_guest_subtitle =>
      'Connectez-vous pour synchroniser vos données en toute sécurité.';

  @override
  String get activity_tracking_status => 'ÉTAT DU SUIVI';

  @override
  String get activity_active => 'Actif';

  @override
  String get activity_description =>
      'Les capteurs de votre téléphone suivent activement vos pas pour la dépense calorique d\'aujourd\'hui.';

  @override
  String get activity_authorize_desc =>
      'Pour suivre vos pas automatiquement, veuillez autoriser la reconnaissance d\'activité.';

  @override
  String get activity_authorize_btn => 'Autoriser le Suivi';

  @override
  String get activity_motivation_low =>
      'Chaque pas compte. Bougeons aujourd\'hui !';

  @override
  String get activity_motivation_mid =>
      'Vous êtes sur la bonne voie ! Une marche rapide pourrait vous aider à atteindre votre objectif.';

  @override
  String get activity_motivation_high =>
      'Presque là ! Vous dépassez vos objectifs d\'activité.';

  @override
  String get activity_motivation_elite =>
      'Exceptionnel ! Vous êtes dans la zone active d\'élite aujourd\'hui.';

  @override
  String get home_scan_food => 'Scanner repas';

  @override
  String get home_go_pro => 'Passer à Pro';

  @override
  String get home_pro_badge => 'PRO';

  @override
  String get home_upgrade_chip => 'Améliorer';

  @override
  String get state_offline => 'Hors ligne';

  @override
  String get state_retry => 'Réessayer';

  @override
  String get state_empty_title => 'Rien ici pour l\'instant';

  @override
  String get state_empty_message => 'Aucune donnée à afficher.';

  @override
  String get state_offline_message =>
      'Vous êtes hors ligne. Les données en cache restent disponibles.';

  @override
  String get state_error_title => 'Une erreur s\'est produite';

  @override
  String get state_error_message => 'Veuillez réessayer.';

  @override
  String get coach_prompt_plan_meal => 'Planifie mon prochain repas';

  @override
  String get coach_prompt_macros => 'Comment sont mes macros ?';

  @override
  String get coach_prompt_tips => 'Conseils nutrition rapides';

  @override
  String get coach_prompt_protein => 'Aide-moi à atteindre les protéines';

  @override
  String get coach_prompt_weekly => 'Bilan hebdomadaire';

  @override
  String get metric_cal => 'Cal';

  @override
  String get metric_protein => 'Protéines';

  @override
  String get metric_carbs => 'Glucides';

  @override
  String get metric_fat => 'Lipides';

  @override
  String get recipe_ingredients => 'Ingrédients';

  @override
  String get recipe_steps => 'Étapes';

  @override
  String get measurement_metric => 'Métrique';

  @override
  String get measurement_imperial => 'Impérial';

  @override
  String get coach_thinking => 'Réflexion…';

  @override
  String get coach_empty_title => 'Comment puis-je vous aider ?';

  @override
  String get coach_empty_subtitle =>
      'Posez une question sur un repas, vos macros ou quoi manger ensuite.';

  @override
  String get coach_suggested => 'SUGGÉRÉ';

  @override
  String get coach_suggest_eat => 'Que dois-je manger ?';

  @override
  String get coach_suggest_track => 'Suis-je sur la bonne voie aujourd\'hui ?';

  @override
  String get coach_suggest_week => 'Planifie ma semaine';

  @override
  String get coach_suggest_protein => 'Atteindre mes protéines';

  @override
  String get coach_error_server =>
      'Le serveur de Fajar a un souci. Patientez un instant et réessayez.';

  @override
  String get coach_error_connection => 'Vérifiez votre connexion et réessayez.';

  @override
  String get home_insight_scan_first => 'Scannez votre premier repas';

  @override
  String get home_insight_go_lighter => 'Un repas plus léger ensuite';

  @override
  String get home_insight_protein_behind => 'Les protéines sont en retard';

  @override
  String get home_insight_next_meal_fits =>
      'Le prochain repas convient aujourd\'hui';

  @override
  String get home_cmp_baseline => 'Établissez votre référence';

  @override
  String get home_cmp_same => 'Comme hier';

  @override
  String home_cmp_below(int kcal) {
    return '$kcal kcal de moins qu\'hier';
  }

  @override
  String home_cmp_above(int kcal) {
    return '$kcal kcal de plus qu\'hier';
  }

  @override
  String get settings_upgrade_to_pro => 'PASSER À PRO';

  @override
  String get settings_emerald_badge => 'ÉMERAUDE';

  @override
  String get coach_limit_title => 'LIMITE QUOTIDIENNE ATTEINTE';

  @override
  String get coach_limit_subtitle =>
      'Passez à Premium pour un coaching illimité et des conseils de repas plus intelligents et adaptés à vos objectifs.';

  @override
  String get coach_limit_btn => 'Passer à l\'illimité pour chatter';

  @override
  String get coach_see_options => 'Voir les options d\'abonnement';

  @override
  String get coach_locked_title => 'Savoir quoi manger ensuite.';

  @override
  String get coach_locked_desc =>
      'Le coach IA lit vos calories, vos macros et vos objectifs du jour, puis vous donne des conseils alimentaires clairs.';

  @override
  String get coach_preview_meal_title => 'Suggestion de prochain repas';

  @override
  String get coach_preview_meal_body =>
      'Meilleur prochain repas : bol de riz au poulet grillé, environ 550 kcal.';

  @override
  String get coach_preview_macro_title => 'Correction des macros';

  @override
  String get coach_preview_macro_body =>
      'Il vous manque encore 45g de protéines et 120g de glucides aujourd\'hui.';

  @override
  String get coach_preview_feedback_title =>
      'Retour sur vos progrès quotidiens';

  @override
  String get coach_preview_feedback_body =>
      'Votre apport en protéines est faible. Ajoutez des œufs, du thon ou du yaourt grec ensuite.';

  @override
  String get report_prompt_title => 'VOTRE RAPPORT HEBDOMADAIRE EST PRÊT';

  @override
  String get report_prompt_subtitle =>
      'Découvrez en détail pourquoi certains jours ont dépassé l\'objectif et comment vous améliorer la semaine prochaine.';

  @override
  String get scan_overlay_scanning => 'ANALYSE PAR VISION IA';

  @override
  String get scan_overlay_desc =>
      'Détection des ingrédients et calcul de la densité nutritionnelle avec Gemini...';

  @override
  String get scan_overlay_manual => 'SAISIR MANUELLEMENT';

  @override
  String get scan_wait_stay => 'Gardez cet écran ouvert';

  @override
  String get scan_wait_longer =>
      'Cela prend plus de temps que d\'habitude — votre résultat arrive.';

  @override
  String get startup_launch_issue => 'Un problème est survenu au lancement';

  @override
  String get startup_initialization_slow =>
      'L\'initialisation prend plus de temps que prévu.';

  @override
  String get startup_setup_failed =>
      'Une erreur est survenue lors de la configuration de l\'app. Réessayez.';

  @override
  String get startup_retry_launch => 'Réessayer le lancement';

  @override
  String get startup_initialization_error => 'Erreur d\'initialisation';

  @override
  String get startup_error_body =>
      'L\'application a rencontré une erreur au démarrage. Essayez de la relancer.';

  @override
  String get startup_reload => 'Recharger';

  @override
  String get activity_live_tracking => 'SUIVI EN DIRECT';

  @override
  String get activity_stationary => 'IMMOBILE';

  @override
  String get activity_steps_today_label => 'PAS AUJOURD\'HUI';

  @override
  String get activity_calories_label => 'CALORIES';

  @override
  String get activity_goal_label => 'OBJECTIF';

  @override
  String get activity_tracking_engine => 'MOTEUR DE SUIVI';

  @override
  String get activity_active_encrypted => 'Actif et chiffré';

  @override
  String get activity_permission_required => 'Autorisation requise';

  @override
  String get activity_steps_synced =>
      'Vos pas sont synchronisés en temps réel.';

  @override
  String get activity_enable_tracking =>
      'Activez le suivi pour voir vos progrès.';

  @override
  String feature_insights_share_error(String error) {
    return 'Erreur de partage : $error';
  }

  @override
  String get feature_insights_empty =>
      'Aucune donnée pour cette semaine pour l\'instant.';

  @override
  String get feature_insights_calorie_trend => 'Tendance des calories';

  @override
  String get feature_insights_ai_coach => 'Conseils du coach IA';

  @override
  String get auth_intro_body =>
      'Votre parcours vers une meilleure santé commence ici.';

  @override
  String get auth_back_to_social => 'Retour à la connexion sociale';

  @override
  String get auth_create_account => 'Créer un compte';

  @override
  String get auth_welcome_back_title => 'Bon retour';

  @override
  String get home_welcome_guest => 'Bienvenue sur Wazn';

  @override
  String get auth_lets_dive => 'Commençons';

  @override
  String get auth_sign_up_short => 'S\'inscrire';

  @override
  String get auth_log_in => 'Se connecter';

  @override
  String get auth_have_account => 'Vous avez déjà un compte ? ';

  @override
  String get auth_no_account => 'Pas encore de compte ? ';

  @override
  String get common_or => 'ou';

  @override
  String get common_today => 'Aujourd\'hui';

  @override
  String get common_yesterday => 'Hier';

  @override
  String get common_tomorrow => 'Demain';

  @override
  String get common_maybe_later => 'Peut-être plus tard';

  @override
  String get settings_category_body_profile_sub =>
      'Mesures corporelles, unités et poids cible';

  @override
  String get settings_category_nutrition_sub =>
      'Objectifs de calories, protéines, glucides et lipides';

  @override
  String get settings_category_preferences_sub =>
      'Thème, langue, rappels et planification des repas';

  @override
  String get settings_category_achievements_sub =>
      'Séries, étapes et récompenses de progression';

  @override
  String get settings_category_account_sub =>
      'Connexion, nom de profil et contrôles du compte';

  @override
  String get settings_category_data_sync_sub =>
      'Sauvegarde, restauration et données locales';

  @override
  String get settings_category_about_sub =>
      'Version, confidentialité, conditions et infos de l\'app';

  @override
  String get home_go_deeper_title => 'Aller plus loin';

  @override
  String get home_go_deeper_body =>
      'Bilans quotidiens IA, tendances des macros et historique complet.';

  @override
  String get home_daily_wellness => 'Bien-être quotidien';

  @override
  String get home_add => 'Ajouter';

  @override
  String get home_daily_score => 'Score quotidien';

  @override
  String get log_monthly_calendar_soon =>
      'Le calendrier mensuel arrive bientôt';

  @override
  String get log_today_subtitle => 'Suivez ce que vous mangez aujourd\'hui';

  @override
  String get log_review_day => 'Revoir cette journée';

  @override
  String get log_scan_food => 'Scanner un aliment';

  @override
  String get feature_templates_saved_meals => 'REPAS ENREGISTRÉS';

  @override
  String get feature_templates_saved_added => 'Repas enregistré ajouté';

  @override
  String get feature_templates_deleted => 'Routine supprimée';

  @override
  String get premium_analysis_title => 'ANALYSE PREMIUM';

  @override
  String get premium_analysis_body =>
      'Obtenez une meilleure version de ce repas selon votre objectif avec des suggestions IA.';

  @override
  String get result_meal_name => 'Nom du repas';

  @override
  String get result_feast => 'Festin';

  @override
  String get result_ai_meal_insight => 'Analyse IA du repas';

  @override
  String get result_ai_meal_body =>
      'Équilibrez ce repas avec une suggestion intelligente.';

  @override
  String get result_add_new_item => 'AJOUTER UN ÉLÉMENT';

  @override
  String get result_total_calories => 'CALORIES TOTALES';

  @override
  String get result_food_details => 'Détails de l\'aliment';

  @override
  String get result_food => 'Aliment';

  @override
  String get result_portion_label => 'Portion';

  @override
  String get result_add_item => 'Ajouter un élément';

  @override
  String get result_nutrition_details => 'Détails nutritionnels';

  @override
  String get result_unlock_nutrition => 'Débloquer les détails nutritionnels';

  @override
  String get result_add_to_log => 'Ajouter au journal';

  @override
  String get paywall_cancel_anytime =>
      'Annulez à tout moment. Sans engagement.';

  @override
  String get paywall_terms_conditions => 'Conditions générales';

  @override
  String get paywall_trial_7_day => 'Essai de 7 jours';

  @override
  String get paywall_scan_limit_subtitle =>
      'Vous avez atteint votre limite de scans gratuits ce mois-ci. Débloquez les scans alimentaires IA illimités et le détail instantané des calories.';

  @override
  String get paywall_coach_subtitle =>
      'Débloquez le coaching illimité, les conseils de macros et les suggestions de repas adaptées à votre journée.';

  @override
  String get paywall_planner_subtitle =>
      'Débloquez les plans hebdomadaires complets, listes de courses, préférences et régénérations de repas IA.';

  @override
  String paywall_reports_subtitle(String feature) {
    return 'Débloquez des analyses plus poussées, des tendances hebdomadaires et des suggestions IA pratiques après chaque $feature.';
  }

  @override
  String get paywall_progress_subtitle =>
      'Débloquez plus de photos de progression, comparaisons et suivi de transformation au-delà de la limite mensuelle gratuite.';

  @override
  String get paywall_ad_removal_subtitle =>
      'Passez à Pro pour supprimer les publicités et débloquer toute l\'expérience nutrition IA.';

  @override
  String get progress_weight_trend => 'Tendance du poids';

  @override
  String get progress_log_custom_weight =>
      'Touchez pour enregistrer votre poids personnalisé';

  @override
  String get log_calories_eaten => 'Calories consommées';

  @override
  String log_kcal_over(int amount) {
    return '$amount au-dessus';
  }

  @override
  String log_kcal_left(int amount) {
    return '$amount restantes';
  }

  @override
  String get log_no_details =>
      'Aucun détail enregistré pour cette journée pour l\'instant.';

  @override
  String log_over_target_insight(int amount) {
    return 'Vous avez enregistré $amount kcal au-dessus de l\'objectif. Revoyez les repas les plus lourds ci-dessous.';
  }

  @override
  String log_low_protein_insight(int calories) {
    return 'Vous avez enregistré $calories kcal et les protéines étaient sous l\'objectif.';
  }

  @override
  String log_water_behind_insight(int calories) {
    return 'Vous avez enregistré $calories kcal. L\'eau est encore en retard aujourd\'hui.';
  }

  @override
  String log_balanced_day_insight(int calories) {
    return 'Vous avez enregistré $calories kcal avec une journée équilibrée jusqu\'ici.';
  }

  @override
  String feature_templates_save_desc(int count) {
    return 'Enregistrez ces $count éléments pour les ajouter plus tard en un toucher.';
  }

  @override
  String get achievement_category_consistency => 'Régularité';

  @override
  String get achievement_category_precision => 'Précision';

  @override
  String get achievement_category_hydration => 'Hydratation';

  @override
  String get achievement_category_logging => 'Journal';

  @override
  String get achievement_category_progress => 'Progrès';

  @override
  String get achievement_unlocked_label => 'Débloqué';

  @override
  String get report_pdf_title => 'RAPPORT NUTRITION IA';

  @override
  String report_pdf_user(String name) {
    return 'Utilisateur : $name';
  }

  @override
  String get report_pdf_weekly_performance => 'PERFORMANCE HEBDOMADAIRE';

  @override
  String get report_pdf_total_protein => 'Protéines totales';

  @override
  String get report_pdf_active_streak => 'Série active';

  @override
  String get report_pdf_grams => 'grammes';

  @override
  String get report_pdf_days => 'jours';

  @override
  String get report_pdf_macro_distribution => 'RÉPARTITION DES MACRONUTRIMENTS';

  @override
  String get report_pdf_nutrient => 'Nutriment';

  @override
  String get report_pdf_total_consumed => 'Total consommé';

  @override
  String get report_pdf_daily_target => 'Objectif quotidien';

  @override
  String get report_pdf_goal_status => 'Statut de l\'objectif';

  @override
  String get report_pdf_carbohydrates => 'Glucides';

  @override
  String get report_pdf_fats => 'Lipides';

  @override
  String get report_pdf_meal_log =>
      'JOURNAL DÉTAILLÉ DES REPAS (7 derniers jours)';

  @override
  String get report_pdf_date => 'Date';

  @override
  String get report_pdf_meal_item => 'Repas';

  @override
  String get report_pdf_type => 'Type';

  @override
  String get report_pdf_footer =>
      'Ce rapport a été généré automatiquement par Wazn AI.';

  @override
  String get report_pdf_tagline => 'Restez régulier, restez en bonne santé.';

  @override
  String get onboarding_safety_safer_pace =>
      'Nous proposerons un rythme plus sûr.';

  @override
  String get onboarding_safety_surplus_capped =>
      'Nous avons limité le surplus pour garder le plan réaliste.';

  @override
  String get onboarding_safety_floor =>
      'Nous avons gardé votre objectif au-dessus du minimum calorique sûr.';

  @override
  String onboarding_safety_floor_extra(String note) {
    return '$note Le minimum calorique sûr a été appliqué.';
  }

  @override
  String onboarding_insight_desk(int calories) {
    return '$calories kcal garde votre plan réaliste avec une routine peu active.';
  }

  @override
  String onboarding_insight_light(int calories) {
    return '$calories kcal vous donne une cible stable adaptée à une activité légère.';
  }

  @override
  String onboarding_insight_athlete(int calories) {
    return '$calories kcal soutient l\'entraînement sans pousser le rythme trop fort.';
  }

  @override
  String onboarding_insight_default(int calories) {
    return '$calories kcal équilibre votre objectif, votre corps et votre activité actuelle.';
  }

  @override
  String get onboarding_tip_desk =>
      'Marcher 20 minutes après les repas est un moyen simple d\'améliorer la régularité.';

  @override
  String get onboarding_tip_light =>
      'Deux séances de mouvement en plus par semaine rendront cet objectif plus durable.';

  @override
  String get onboarding_tip_athlete =>
      'Répartissez les protéines à chaque repas pour soutenir la récupération et l\'appétit.';

  @override
  String get onboarding_tip_bulk =>
      'Placez la plupart des calories supplémentaires autour de l\'entraînement pour la performance.';

  @override
  String get onboarding_tip_default =>
      'Construisez vos repas autour des protéines pour atteindre l\'objectif plus facilement.';

  @override
  String get paywall_slide_grilled_chicken => 'Poulet grillé';

  @override
  String get paywall_slide_rice => 'Riz';

  @override
  String get paywall_slide_avocado => 'Avocat';

  @override
  String get paywall_slide_toast => 'Toast';

  @override
  String get paywall_slide_cherry_tomatoes => 'Tomates cerises';

  @override
  String get paywall_slide_salmon => 'Filet de saumon';

  @override
  String get paywall_slide_sweet_potato => 'Patate douce';

  @override
  String get paywall_slide_broccoli => 'Brocoli';

  @override
  String get paywall_slide_boiled_eggs => 'Œufs bouillis';

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
  String get paywall_slide_eggs_portion => '2 grands';

  @override
  String get paywall_slide_toast_portion => '2 tranches';

  @override
  String get scan_step_uploading =>
      'Téléchargement de l\'image de nourriture...';

  @override
  String get scan_step_scanning => 'Analyse des formes visuelles...';

  @override
  String get scan_step_ingredients => 'Identification des ingrédients...';

  @override
  String get scan_step_portions => 'Estimation des tailles de portion...';

  @override
  String get scan_step_calories => 'Calcul de la densité calorique...';

  @override
  String get scan_step_macros => 'Équilibrage des macronutriments...';

  @override
  String get scan_step_finalizing =>
      'Finalisation de la fiche nutritionnelle...';

  @override
  String get common_camera => 'Caméra';

  @override
  String get assistant_quick_macros => 'Ajuster mes macros';

  @override
  String get assistant_quick_next_meal => 'Que devrais-je manger ensuite ?';

  @override
  String get assistant_quick_snack => 'En-cas riche en protéines';

  @override
  String assistant_meals_logged_today(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Basé sur $count repas enregistrés aujourd\'hui',
      one: 'Basé sur 1 repas enregistré aujourd\'hui',
      zero: 'Basé sur aucun repas enregistré aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get assistant_ask_coach_header => 'Demandez à votre coach';

  @override
  String get assistant_brief_today => 'Briefing du coach d\'aujourd\'hui';

  @override
  String get assistant_live => 'En direct';

  @override
  String get assistant_brief_left => 'Restant';

  @override
  String get assistant_protein_gap => 'Déficit en protéines';

  @override
  String get assistant_to_goal => 'pour l\'objectif';

  @override
  String get assistant_last_meal => 'Dernier repas';

  @override
  String get assistant_next_move => 'Prochaine étape';

  @override
  String get assistant_no_meals_logged =>
      'Aucun repas enregistré pour le moment';

  @override
  String get assistant_action_log_meal =>
      'Enregistrez un repas pour un coaching précis';

  @override
  String get assistant_action_protein =>
      'Donnez la priorité aux protéines ensuite';

  @override
  String get assistant_action_light => 'Gardez le choix suivant léger';

  @override
  String get assistant_action_balanced =>
      'Restez équilibré pour votre prochain repas';

  @override
  String get assistant_analyze_image_prompt => 'Analyser cette image.';

  @override
  String common_items_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String get settings_weight_loss_progress =>
      'Progression de la perte de poids';

  @override
  String get settings_weight_gain_progress =>
      'Progression de la prise de poids';

  @override
  String get settings_weight_start => 'Départ';

  @override
  String get settings_weight_current => 'Actuel';

  @override
  String get settings_weight_target => 'Objectif';

  @override
  String get settings_goal_reached => 'Objectif atteint ! 🎉';

  @override
  String settings_left_to_reach_target(String amount, String unit) {
    return 'Plus que $amount $unit pour atteindre l\'objectif';
  }

  @override
  String get settings_macro_calorie_split =>
      'Répartition des calories par macro';

  @override
  String get settings_macro_calorie_split_desc =>
      'Pourcentage des calories totales fournies par chaque macro';

  @override
  String get settings_step_tracking => 'Suivi des pas';

  @override
  String get settings_syncing_activity =>
      'Synchronisation des données d\'activité...';

  @override
  String get settings_sync_now => 'Synchroniser maintenant';

  @override
  String get settings_sync_now_desc =>
      'Actualiser les pas et les calories estimées';

  @override
  String settings_last_synced(String time) {
    return 'Dernière synchronisation $time';
  }

  @override
  String get settings_disconnect_steps => 'Désactiver le suivi des pas';

  @override
  String get settings_disconnect_steps_desc =>
      'Arrêter d\'écouter les mises à jour des pas du téléphone';

  @override
  String get settings_status_enabled => 'Suivi activé';

  @override
  String get settings_status_denied => 'Autorisation refusée';

  @override
  String get settings_status_unsupported => 'Appareil non pris en charge';

  @override
  String get settings_status_error => 'Erreur de suivi';

  @override
  String get settings_status_off => 'Suivi désactivé';

  @override
  String get settings_status_connected => 'Connecté';

  @override
  String get settings_status_not_connected => 'Non connecté';

  @override
  String get settings_gender_male => 'Homme';

  @override
  String get settings_gender_female => 'Femme';

  @override
  String get settings_gender_other => 'Autre';

  @override
  String get settings_age_unit => 'ans';

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
  String get paywall_unlock_snapcal_pro => 'Débloquer Wazn Pro';

  @override
  String get paywall_barcode_title => 'Débloquer le scanner de codes-barres';

  @override
  String get paywall_barcode_subtitle =>
      'Enregistrez instantanément les aliments emballés en scannant leurs codes-barres';

  @override
  String paywall_free_scans_used_title(int used, int limit) {
    return 'Vous avez utilisé $used/$limit scans gratuits ce mois-ci';
  }

  @override
  String get paywall_unlimited_scanning_subtitle =>
      'Passez à Pro pour débloquer les scans illimités';

  @override
  String get paywall_unlimited_scanning_title =>
      'Débloquer les scans illimités';

  @override
  String get paywall_scan_track_subtitle =>
      'Passez à Pro pour scanner et suivre tous vos repas';

  @override
  String get paywall_ai_coaching_title => 'Débloquer le coaching IA illimité';

  @override
  String get paywall_ai_coaching_subtitle =>
      'Guidance nutritionnelle personnelle 24/7';

  @override
  String get paywall_smart_planning_title =>
      'Débloquer la planification intelligente';

  @override
  String get paywall_smart_planning_subtitle =>
      'Plans quotidiens personnalisés selon vos objectifs';

  @override
  String get paywall_shopping_lists_title => 'Listes de courses automatiques';

  @override
  String get paywall_shopping_lists_subtitle =>
      'Gagnez du temps avec l\'agrégation intelligente des courses';

  @override
  String get paywall_progress_journey_title => 'Parcours visuel de progression';

  @override
  String get paywall_progress_journey_subtitle =>
      'Suivez vos photos de transformation corporelle';

  @override
  String get paywall_analytics_title => 'Analyses métaboliques avancées';

  @override
  String get paywall_analytics_subtitle =>
      'Débloquez des tendances nutritionnelles personnalisées';

  @override
  String get paywall_focused_title => 'Expérience 100 % concentrée';

  @override
  String get paywall_focused_subtitle =>
      'Supprimez toutes les publicités et interruptions';

  @override
  String get paywall_upgrade_experience_title => 'Améliorez votre expérience';

  @override
  String get paywall_upgrade_experience_subtitle =>
      'Débloquez toutes les fonctions premium aujourd\'hui';

  @override
  String get paywall_benefit_unlimited_scans => 'Scans illimités';

  @override
  String get paywall_benefit_ai_guidance => 'Guidance IA';

  @override
  String get paywall_benefit_full_history => 'Historique complet';

  @override
  String get paywall_benefit_weekly_reports => 'Rapports hebdomadaires';

  @override
  String get paywall_benefit_ad_free => 'Sans publicité';

  @override
  String get paywall_benefit_smart_planner => 'Planificateur intelligent';

  @override
  String paywall_price_target(String price) {
    return '$price cible';
  }

  @override
  String get paywall_billing_monthly => 'Facturé mensuellement';

  @override
  String get paywall_billing_lifetime => 'Paiement unique';

  @override
  String get assistant_action_fix_macros => 'Corriger mes macros du jour';

  @override
  String get assistant_action_plan_next_meal => 'Planifier mon prochain repas';

  @override
  String get assistant_action_light_dinner => 'Suggérer un dîner léger';

  @override
  String assistant_coaching_with_meals(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Coaching avec $count repas enregistrés aujourd\'hui',
      one: 'Coaching avec 1 repas enregistré aujourd\'hui',
      zero: 'Coaching sans repas enregistré aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get assistant_start_new_chat => 'Démarrer un nouveau chat';

  @override
  String get assistant_new_chat => 'Nouveau chat';

  @override
  String get assistant_coach_insight => 'Conseil du coach';

  @override
  String get assistant_recipe_estimated_macros =>
      'Plan de recette avec macros estimées';

  @override
  String get assistant_personalized_from_today =>
      'Personnalisé selon votre nutrition du jour';

  @override
  String get assistant_step_recipe_plan => 'Plan de recette étape par étape';

  @override
  String get assistant_recipe => 'Recette';

  @override
  String get assistant_ingredients => 'Ingrédients';

  @override
  String get assistant_what_to_do => 'Que faire';

  @override
  String get assistant_recipe_plan => 'Plan de recette';

  @override
  String get assistant_plan_meal => 'Planifier un repas';

  @override
  String get assistant_adjust_macros => 'Ajuster les macros';

  @override
  String get assistant_ask_follow_up => 'Poser une question';

  @override
  String activity_steps_goal(int steps) {
    final intl.NumberFormat stepsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Objectif : $stepsString pas';
  }

  @override
  String get activity_unlock_pro_title =>
      'Débloquer les fonctions Pro d\'activité';

  @override
  String get activity_unlock_pro_subtitle =>
      'Voyez votre semaine : pas quotidiens, votre série, vos séances depuis Health Connect et un objectif calorique qui s’adapte à votre activité.';

  @override
  String get activity_manual_workouts => 'Entraînements manuels';

  @override
  String get activity_no_manual_workouts =>
      'Aucun entraînement manuel enregistré aujourd\'hui.';

  @override
  String get activity_default_workout => 'Entraînement';

  @override
  String get activity_add_workout => 'Ajouter un entraînement';

  @override
  String get activity_workout_type => 'Type d\'entraînement';

  @override
  String get activity_minutes => 'Minutes';

  @override
  String get activity_save_workout => 'Enregistrer l\'entraînement';

  @override
  String activity_insight_goal_met(int steps) {
    final intl.NumberFormat stepsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Vous avez fait en moyenne $stepsString pas cette semaine et atteignez votre objectif.';
  }

  @override
  String activity_insight_goal_gap(int steps) {
    final intl.NumberFormat stepsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Vous avez fait en moyenne $stepsString pas cette semaine. Une courte marche peut aider à combler l\'écart.';
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
      'Initialisation du moteur intelligent de calories...';

  @override
  String get splash_status_database =>
      'Ouverture de la base de données chiffrée...';

  @override
  String get splash_status_ai_gateways =>
      'Configuration du coach IA et de Gemini...';

  @override
  String get splash_status_dashboard =>
      'Calibration du tableau de bord bien-être...';

  @override
  String get splash_status_sync_profile => 'Synchronisation du profil cloud...';

  @override
  String get auth_google_sign_in_failed => 'Échec de la connexion Google';

  @override
  String get auth_facebook_sign_in_failed => 'Échec de la connexion Facebook';

  @override
  String get auth_err_network =>
      'Pas de connexion internet. Vérifiez votre connexion et réessayez.';

  @override
  String get auth_err_wrong_credentials =>
      'L’e-mail et le mot de passe ne correspondent pas. Vérifiez-les et réessayez.';

  @override
  String get auth_err_email_in_use =>
      'Un compte existe déjà avec cet e-mail. Connectez-vous plutôt.';

  @override
  String get auth_err_weak_password =>
      'Choisissez un mot de passe plus sûr, d’au moins 8 caractères.';

  @override
  String get auth_err_invalid_email => 'Saisissez une adresse e-mail valide.';

  @override
  String get auth_err_too_many =>
      'Trop de tentatives. Patientez quelques minutes et réessayez.';

  @override
  String get auth_err_other_provider =>
      'Cet e-mail est déjà inscrit autrement. Utilisez l’option choisie la première fois : Google, Facebook ou e-mail.';

  @override
  String get auth_err_disabled => 'Ce compte a été désactivé.';

  @override
  String get auth_err_unavailable =>
      'Cette option de connexion n’est pas disponible sur ce téléphone.';

  @override
  String get auth_err_unknown => 'Connexion impossible. Veuillez réessayer.';

  @override
  String get auth_email_required => 'Saisissez votre adresse e-mail.';

  @override
  String get auth_password_required => 'Saisissez votre mot de passe.';

  @override
  String get auth_password_too_short => 'Utilisez au moins 8 caractères.';

  @override
  String get auth_forgot_password => 'Mot de passe oublié ?';

  @override
  String auth_reset_sent(String email) {
    return 'Si un compte existe pour $email, nous lui avons envoyé un lien pour réinitialiser le mot de passe.';
  }

  @override
  String get auth_reset_enter_email =>
      'Saisissez votre e-mail ci-dessus, puis touchez à nouveau « Mot de passe oublié ? ».';

  @override
  String auth_google_sign_in_failed_code(String code) {
    return 'Échec de la connexion Google ($code). Veuillez réessayer.';
  }

  @override
  String auth_firebase_google_sign_in_failed(String code) {
    return 'Firebase n\'a pas pu terminer la connexion Google ($code).';
  }

  @override
  String get barcode_unknown_product => 'Produit inconnu';

  @override
  String get barcode_default_portion => 'par portion/100 g';

  @override
  String get activity_calorie_estimate_disclaimer =>
      'Les calories sont estimées à partir des pas et peuvent ne pas être exactes.';

  @override
  String get activity_estimated_calories => 'Calories estimées';

  @override
  String get activity_step_streak => 'Série de pas';

  @override
  String get activity_not_connected_title => 'Connectez Health Connect';

  @override
  String get activity_not_connected_body =>
      'Wazn lit vos pas depuis Health Connect. Il n’y écrit jamais rien.';

  @override
  String get activity_connect => 'Connecter';

  @override
  String get activity_calories_estimated_hint => 'Estimées';

  @override
  String get activity_calories_measured_hint => 'Mesurées';

  @override
  String get activity_this_week => 'Cette semaine';

  @override
  String get activity_avg_per_day => 'Moyenne par jour';

  @override
  String get activity_best_day => 'Meilleur jour';

  @override
  String get activity_days_goal_met => 'Jours atteints';

  @override
  String get activity_no_workout_today => 'Pas de séance aujourd’hui';

  @override
  String activity_workout_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get activity_workout_calories => 'Calories d\'entraînement';

  @override
  String get activity_score => 'Score d\'activité';

  @override
  String get log_health_title => 'Santé Wazn';

  @override
  String get log_key_metrics => 'Métriques clés';

  @override
  String get log_customize => 'Personnaliser';

  @override
  String get log_metric_water => 'Eau';

  @override
  String get log_metric_energy_burned => 'Énergie brûlée';

  @override
  String get log_metric_steps => 'Pas';

  @override
  String get log_metric_calories_intake => 'Calories consommées';

  @override
  String get log_macro_unlock_tracking => 'Débloquer le suivi des macros';

  @override
  String get log_metric_carbs => 'Glucides';

  @override
  String get log_metric_fat => 'Lipides';

  @override
  String get log_metric_protein => 'Protéines';

  @override
  String get log_metric_steps_unit => 'pas';

  @override
  String get log_period_day => 'J';

  @override
  String get log_period_week => 'S';

  @override
  String get log_period_month => 'M';

  @override
  String get log_period_three_months => '3M';

  @override
  String get log_period_year => 'A';

  @override
  String get log_detail_this_day => 'Ce jour';

  @override
  String get log_detail_this_week => 'Cette semaine';

  @override
  String get log_detail_this_month => 'Ce mois';

  @override
  String get log_detail_this_three_months => '3 derniers mois';

  @override
  String get log_detail_this_year => 'Cette année';

  @override
  String log_metric_per_day_avg(String unit) {
    return '$unit par jour (moy.)';
  }

  @override
  String get log_metric_goal_hit => 'Vous êtes sur la bonne voie.';

  @override
  String get log_metric_goal_miss => 'Vous n\'avez pas atteint votre objectif.';

  @override
  String log_metric_left(String value) {
    return '$value restants';
  }

  @override
  String get log_metric_below_range => 'Sous la plage';

  @override
  String get log_metric_no_data => 'Aucune donnée';

  @override
  String get log_metric_locked => 'Verrouillé';

  @override
  String get log_metric_history_locked => 'L\'historique complet est Pro';

  @override
  String get log_metric_detail_list_title => 'Cette période';

  @override
  String get common_days => 'jours';

  @override
  String get aha_prompt_title => 'Vous venez d\'économiser 10 minutes';

  @override
  String get aha_prompt_subtitle =>
      'Imaginez économiser ce temps chaque jour. Passez à Pro pour des scans photo illimités et un suivi sans effort.';

  @override
  String get aha_prompt_btn => 'Passer à Pro';

  @override
  String get macro_locked_title => 'Les macros sont Pro';

  @override
  String get macro_locked_body =>
      'Déverrouillez les détails protéines, glucides et lipides avec Wazn Pro.';

  @override
  String get macro_unlock_cta => 'Déverrouiller les macros';

  @override
  String get macro_locked_placeholder => 'Verrouillé';

  @override
  String get macro_unlock_card_title =>
      'Débloquez votre répartition des macros';

  @override
  String get macro_unlock_card_body =>
      'Voyez les progrès des protéines, glucides et lipides pour chaque repas.';

  @override
  String get common_unlock => 'Déverrouiller';

  @override
  String get scan_choice_title => 'Enregistrer un repas';

  @override
  String get scan_choice_subtitle =>
      'Choisissez le moyen le plus rapide d\'ajouter votre repas.';

  @override
  String get scan_choice_food_title => 'Scanner une photo';

  @override
  String get scan_choice_food_subtitle =>
      'Prenez une photo pour une analyse nutritionnelle instantanée.';

  @override
  String get scan_choice_barcode_title => 'Scanner le code-barres';

  @override
  String get scan_choice_barcode_subtitle =>
      'Trouvez des aliments emballés en scannant leur code-barres.';

  @override
  String get scan_choice_voice_title => 'Saisie vocale';

  @override
  String get scan_choice_voice_subtitle =>
      'Dites ce que vous avez mangé puis vérifiez le résultat.';

  @override
  String get planner_empty_headline =>
      'Planification de repas intelligente et personnalisée sur 7 jours';

  @override
  String get planner_empty_body =>
      'Wazn conçoit vos repas autour des calories, des macros, des préférences et de la liste de courses.';

  @override
  String get planner_empty_benefit_adaptive => 'Guidage quotidien adaptatif';

  @override
  String get planner_empty_benefit_macros => 'Repas équilibrés en macros';

  @override
  String get planner_empty_benefit_grocery => 'Liste de courses automatique';

  @override
  String get planner_adjust_preferences => 'Ajuster les préférences';

  @override
  String get planner_meals_unit => 'repas';

  @override
  String get planner_items_unit => 'articles';

  @override
  String get planner_avg_plan => 'Plan moyen';

  @override
  String get planner_protein_coverage => 'Protéines';

  @override
  String get planner_guidance_protein =>
      'Le retard sur les protéines est important ; privilégiez un prochain repas riche en protéines.';

  @override
  String get planner_guidance_light =>
      'Les calories sont limitées ; gardez votre prochain repas léger.';

  @override
  String get planner_guidance_balanced =>
      'Vous êtes sur la bonne voie ; suivez vos repas planifiés.';

  @override
  String get planner_prep_time => 'Temps de préparation';

  @override
  String get planner_prep_quick => 'Rapide';

  @override
  String get planner_prep_balanced => 'Équilibré';

  @override
  String get planner_prep_batch => 'Préparation par lots';

  @override
  String get planner_budget => 'Budget';

  @override
  String get planner_budget_value => 'Économique';

  @override
  String get planner_budget_standard => 'Standard';

  @override
  String get planner_budget_premium => 'Premium';

  @override
  String get planner_advanced_preferences => 'Préférences avancées';

  @override
  String get planner_advanced_preferences_body =>
      'Les allergies, les aversions, l\'équipement, les portions et les jours d\'entraînement arriveront dans une future mise à jour.';

  @override
  String get planner_swap_title => 'Échanger le repas';

  @override
  String get planner_swap_intent => 'Choisissez l\'objectif';

  @override
  String get planner_swap_lower_calorie => 'Moins de calories';

  @override
  String get planner_swap_higher_protein => 'Plus de protéines';

  @override
  String get planner_swap_faster_prep => 'Préparation plus rapide';

  @override
  String get planner_swap_cheaper => 'Option moins chère';

  @override
  String get planner_swap_custom_note => 'Ajouter une note facultative';

  @override
  String get planner_swap_note_hint => 'ex. poulet, salade, pâtes...';

  @override
  String get planner_swap_generate => 'Générer un échange';

  @override
  String get planner_swap_with_note => 'Échanger avec note';

  @override
  String get planner_swap_loading => 'Recherche d\'un échange...';

  @override
  String get planner_swap_success =>
      'Repas remplacé par une alternative pratique.';

  @override
  String get planner_grocery_ready => 'Déjà en ma possession';

  @override
  String get planner_already_have => 'Déjà en possession';

  @override
  String get planner_rebalance_notice_light =>
      'Plan rééquilibré : les repas restants sont plus légers pour aujourd\'hui.';

  @override
  String get planner_rebalance_notice_protein =>
      'Plan rééquilibré : les repas restants sont axés sur les protéines.';

  @override
  String get planner_today_plan => 'Plan d\'aujourd\'hui';

  @override
  String get planner_today_meals => 'Repas d\'aujourd\'hui';

  @override
  String get planner_planned_unit => 'planifiés';

  @override
  String get planner_planned_for_today => 'Planifié pour aujourd\'hui';

  @override
  String get planner_logged => 'Enregistré';

  @override
  String get planner_upcoming => 'À venir';

  @override
  String get planner_alert_next_protein =>
      'Rendez votre prochain repas riche en protéines';

  @override
  String get planner_alert_on_track => 'Plan sur les rails';

  @override
  String get planner_alert_follow_plan =>
      'Suivez votre prochain repas planifié';

  @override
  String get planner_alert_fix_it => 'Ajuster';

  @override
  String get planner_week_complete_title => 'Ce plan de repas est terminé';

  @override
  String get planner_generate_current_week =>
      'Générer le plan de cette semaine';

  @override
  String get settings_milliliters_unit => 'ml';

  @override
  String get log_customize_metrics_desc =>
      'Choisissez les métriques qui s\'affichent sur votre tableau de bord';

  @override
  String get log_metric_full_history_locked => 'Historique complet verrouillé';

  @override
  String get log_metric_full_history_upgrade =>
      'Passez à Pro pour voir l\'historique au-delà de 14 jours';

  @override
  String planner_swap_replacing(Object food) {
    return 'Remplacement : $food';
  }

  @override
  String planner_rebalance_notice_adjusted(Object count) {
    return 'Plan rééquilibré : $count repas restants ajustés pour aujourd\'hui.';
  }

  @override
  String planner_alert_protein_short(Object grams) {
    return 'Il vous manque ${grams}g de protéines aujourd\'hui';
  }

  @override
  String planner_week_complete_body(Object date) {
    return 'Votre dernier plan s\'est terminé le $date. Générez un nouveau plan pour la semaine en cours.';
  }

  @override
  String log_metric_goal_value(Object value) {
    return 'cible $value';
  }

  @override
  String get onboarding_pace_gentle => 'Doux';

  @override
  String get onboarding_pace_balanced => 'Équilibré';

  @override
  String get onboarding_pace_faster => 'Plus rapide';

  @override
  String get onboarding_plan_protein => 'Protéines';

  @override
  String get onboarding_plan_carbs => 'Glucides';

  @override
  String get onboarding_plan_fat => 'Lipides';

  @override
  String onboarding_plan_grams(int grams) {
    return '${grams}g';
  }

  @override
  String get onboarding_plan_start => 'Commencer le plan';

  @override
  String get onboarding_already_account => 'Vous avez déjà un compte ?';

  @override
  String get onboarding_scan_scanning => 'Analyse de votre repas...';

  @override
  String get onboarding_scan_ai_label => 'IA';

  @override
  String get onboarding_scan_kcal => 'kcal';

  @override
  String get onboarding_goal_lose => 'Perdre du poids';

  @override
  String get onboarding_goal_maintain => 'Maintenir';

  @override
  String get onboarding_goal_build => 'Gagner du muscle';

  @override
  String get onboarding_goal_track => 'Suivre seulement';

  @override
  String get onboarding_finish_error =>
      'Impossible de créer votre plan. Veuillez réessayer.';

  @override
  String get result_set_weight => 'Définir le poids';

  @override
  String get result_cancel => 'Annuler';

  @override
  String get result_save => 'Enregistrer';

  @override
  String get result_tap_to_adjust =>
      'Touchez un aliment pour ajuster la portion';

  @override
  String get result_retake => 'Reprendre';

  @override
  String result_scans_left(int remaining, int total) {
    return 'Il vous reste $remaining scans sur $total';
  }

  @override
  String get result_added => 'Ajouté';

  @override
  String get result_save_log => 'Enregistrer';

  @override
  String get result_unlock_title => 'Débloquez des analyses plus poussées';

  @override
  String get result_unlock_subtitle =>
      'Score santé, coaching IA et analyses de repas';

  @override
  String get result_no_items_detected =>
      'Aucun aliment détecté — ajoutez-en un ci-dessous ou reprenez la photo';

  @override
  String get result_confidence_estimated => 'Estimé';

  @override
  String get result_confidence_low => 'Faible';

  @override
  String get result_health_excellent => 'Excellent';

  @override
  String get result_health_good => 'Bon';

  @override
  String get result_health_okay => 'Correct';

  @override
  String get result_health_poor => 'Médiocre';

  @override
  String get result_health_bad => 'Mauvais';

  @override
  String get result_no_items => 'Aucun aliment';

  @override
  String result_foods_detected(int count) {
    return '$count aliments détectés';
  }

  @override
  String get result_food_item => 'Aliment';

  @override
  String result_removed(String name) {
    return '$name supprimé';
  }

  @override
  String get result_undo => 'Annuler';

  @override
  String get result_rename => 'Renommer';

  @override
  String get result_food_name => 'Nom de l’aliment';

  @override
  String get result_discard_title => 'Abandonner le scan ?';

  @override
  String get result_discard_body =>
      'Vos aliments scannés n’ont pas encore été enregistrés.';

  @override
  String get result_keep_editing => 'Continuer';

  @override
  String get result_discard => 'Abandonner';

  @override
  String get result_not_matched => 'Non reconnu · touchez pour corriger';

  @override
  String get result_not_in_database => 'Absent de la base de données';

  @override
  String get result_assign_food => 'Associer un aliment';

  @override
  String get macro_no_meals_yet => 'Aucun repas enregistré';

  @override
  String get macro_targets_cta => 'Objectifs quotidiens et suivi';

  @override
  String get macro_pro_label => 'Pro';

  @override
  String get macro_ring_unlock_title => 'Voyez vos chiffres exacts';

  @override
  String get macro_ring_unlock_body =>
      'Débloquez les grammes et les objectifs quotidiens';

  @override
  String macro_ring_on_track(String macro) {
    return 'Vous êtes sur la bonne voie pour $macro — débloquez les grammes exacts';
  }

  @override
  String result_add_to_log_kcal(String calories) {
    return 'Ajouter au journal · $calories kcal';
  }

  @override
  String planner_teaser_locked_summary(int count, String kcal) {
    return '+$count repas de plus · $kcal kcal planifiées';
  }

  @override
  String get planner_teaser_title => 'Débloquez les plans complets';

  @override
  String get planner_teaser_subtitle =>
      'Obtenez votre programme quotidien complet, adapté à vos objectifs';

  @override
  String get planner_teaser_cta => 'Débloquer avec Wazn Pro';

  @override
  String paywall_disclosure_trial_year(int days, String price) {
    return 'Gratuit pendant $days jours, puis $price par an. Annulez avant pour éviter les frais.';
  }

  @override
  String paywall_disclosure_trial_month(int days, String price) {
    return 'Gratuit pendant $days jours, puis $price par mois. Annulez avant pour éviter les frais.';
  }

  @override
  String paywall_disclosure_year(String price) {
    return '$price par an. Renouvellement automatique jusqu’à annulation.';
  }

  @override
  String paywall_disclosure_month(String price) {
    return '$price par mois. Renouvellement automatique jusqu’à annulation.';
  }

  @override
  String paywall_disclosure_lifetime(String price) {
    return '$price, paiement unique. Sans abonnement.';
  }

  @override
  String paywall_disclosure_intro_year(String introPrice, String price) {
    return '$introPrice la première année, puis $price par an. Renouvellement automatique jusqu’à annulation.';
  }

  @override
  String paywall_disclosure_intro_month(String introPrice, String price) {
    return '$introPrice le premier mois, puis $price par mois. Renouvellement automatique jusqu’à annulation.';
  }

  @override
  String paywall_intro_first_year(String introPrice) {
    return '$introPrice la première année';
  }

  @override
  String paywall_intro_first_month(String introPrice) {
    return '$introPrice le premier mois';
  }

  @override
  String home_goal_activity_bonus(int kcal) {
    return '+$kcal kcal gagnées grâce à l’activité';
  }

  @override
  String home_metric_of_goal(String goal, String unit) {
    return 'sur $goal $unit';
  }

  @override
  String get water_unit_ml => 'ml';

  @override
  String home_kcal_short(int kcal) {
    return '$kcal kcal';
  }

  @override
  String home_kcal_estimated_short(int kcal) {
    return '~$kcal kcal';
  }

  @override
  String get log_this_week => 'Cette semaine';

  @override
  String log_week_average(String value) {
    return '$value en moyenne';
  }

  @override
  String log_week_on_target(String count, String total) {
    return '$count sur $total dans l\'objectif';
  }

  @override
  String get log_week_no_data =>
      'Rien enregistré cette semaine pour l\'instant';

  @override
  String log_vs_average_above(String value) {
    return '$value au-dessus de votre moyenne sur 7 jours';
  }

  @override
  String log_vs_average_below(String value) {
    return '$value en dessous de votre moyenne sur 7 jours';
  }

  @override
  String get log_vs_average_same => 'Pile sur votre moyenne sur 7 jours';

  @override
  String get log_meal_split => 'D\'où viennent les calories';

  @override
  String get macro_target_met => 'Objectif atteint';

  @override
  String macro_grams_to_go(String value) {
    return 'Encore $value g';
  }

  @override
  String macro_targets_met_count(String count, String total) {
    return '$count sur $total objectifs atteints';
  }

  @override
  String get result_unlock_personal_title =>
      'Est-ce que ça rentre dans votre journée ?';

  @override
  String get result_unlock_personal_body =>
      'Pro compare ce repas à vos objectifs de protéines, glucides et lipides';

  @override
  String get home_macro_empty => 'Scannez un repas pour voir votre répartition';

  @override
  String get home_section_plan_coach => 'Plan et coach';

  @override
  String get assistant_home_subtitle => 'Conseils personnalisés par IA';

  @override
  String home_offer_percent_off(String value) {
    return '-$value%';
  }

  @override
  String get home_offer_ends_soon => 'Bientôt fini';

  @override
  String get settings_guest_sync =>
      'Synchronisez vos données entre vos appareils';

  @override
  String settings_value_range_hint(String min, String max) {
    return 'Entre $min et $max';
  }

  @override
  String settings_value_out_of_range(String min, String max) {
    return 'Saisissez une valeur entre $min et $max';
  }

  @override
  String settings_macros_total(String kcal) {
    return 'Vos macros totalisent $kcal kcal';
  }

  @override
  String get settings_macros_match_goal =>
      'Correspond à votre objectif calorique quotidien';

  @override
  String settings_macros_over_goal(String kcal) {
    return '$kcal kcal au-dessus de votre objectif quotidien';
  }

  @override
  String settings_macros_under_goal(String kcal) {
    return '$kcal kcal en dessous de votre objectif quotidien';
  }

  @override
  String get settings_calories_adjust_macros_note =>
      'Modifier vos calories ajuste vos macros en conséquence, en conservant le même équilibre.';

  @override
  String get settings_recalculate_title =>
      'Mettre à jour vos objectifs quotidiens ?';

  @override
  String get settings_recalculate_body =>
      'Vos calories et macros ont été calculées à partir de vos anciennes données. Les recalculer maintenant ? Les objectifs que vous avez définis seront remplacés.';

  @override
  String get settings_recalculate_keep => 'Garder les miens';

  @override
  String get settings_recalculate_apply => 'Recalculer';

  @override
  String settings_maintenance_estimate(String kcal) {
    return 'Vous brûlez environ $kcal kcal par jour';
  }

  @override
  String get settings_daily_target => 'Objectif quotidien';

  @override
  String get settings_from_maintenance => 'de l\'entretien';

  @override
  String get settings_goal_source_profile => 'Depuis votre profil';

  @override
  String get settings_goal_source_custom => 'Je les définis';

  @override
  String get settings_goal_source_note_profile =>
      'Les objectifs se mettent à jour quand votre âge, taille ou poids changent.';

  @override
  String get settings_goal_source_note_custom =>
      'Vos chiffres restent exactement tels que vous les avez définis.';

  @override
  String settings_percent_of_calories(String percent) {
    return '$percent% des calories';
  }

  @override
  String get settings_group_about_you => 'À propos de vous';

  @override
  String get settings_group_weight => 'Poids';

  @override
  String get settings_group_activity => 'Activité';

  @override
  String get settings_group_adjust => 'Ajuster';

  @override
  String get settings_group_daily_targets => 'Objectifs quotidiens';

  @override
  String get settings_water_goal => 'Eau';

  @override
  String get settings_step_goal => 'Pas';

  @override
  String get settings_unit_ml => 'ml';

  @override
  String get settings_unit_steps => 'pas';

  @override
  String get settings_sex => 'Sexe';

  @override
  String get settings_sex_hint => 'Utilisé dans la formule des calories';

  @override
  String get settings_activity_hint => 'Détermine ce que vous brûlez';

  @override
  String get settings_starting_weight_hint => 'Votre référence de progression';

  @override
  String get settings_starting_weight => 'Départ';

  @override
  String get settings_macros_move_note =>
      'Vos macros suivent, en conservant le même équilibre';

  @override
  String get planner_build_week => 'Créez votre semaine';

  @override
  String planner_step_of(Object step, Object total) {
    return 'Étape $step sur $total';
  }

  @override
  String get planner_goal_summary => 'Objectif quotidien';

  @override
  String get planner_edit_goals => 'Modifier les objectifs';

  @override
  String get planner_cooking_time => 'Temps de cuisine';

  @override
  String get planner_cooking_quick => 'Rapide';

  @override
  String get planner_cooking_balanced => 'Équilibré';

  @override
  String get planner_cooking_enjoy => 'J\'aime cuisiner';

  @override
  String get planner_plan_style => 'Style du plan';

  @override
  String get planner_style_budget => 'Économique';

  @override
  String get planner_style_protein => 'Riche en protéines';

  @override
  String get planner_style_simple => 'Ingrédients simples';

  @override
  String get planner_style_variety => 'Plus de variété';

  @override
  String get planner_food_preferences => 'Préférences alimentaires';

  @override
  String get planner_no_restrictions => 'Aucune restriction';

  @override
  String get planner_foods_avoid => 'Aliments à éviter';

  @override
  String get planner_foods_avoid_hint => 'ex. champignons, arachides';

  @override
  String get planner_choose_cuisines => 'Choisissez les cuisines';

  @override
  String get planner_cuisine_latin => 'Latine';

  @override
  String get planner_cuisine_african => 'Africaine';

  @override
  String get planner_cuisine_european => 'Européenne';

  @override
  String get planner_cuisine_surprise => 'Surprenez-moi';

  @override
  String get planner_shopping_style => 'Style d\'achat';

  @override
  String get planner_shopping_save => 'Économiser';

  @override
  String get planner_shopping_balanced => 'Équilibré';

  @override
  String get planner_shopping_premium => 'Ingrédients premium';

  @override
  String get planner_use_pantry => 'Utiliser les produits du placard';

  @override
  String get planner_plan_leftovers => 'Planifier les restes';

  @override
  String get planner_repeat_breakfasts =>
      'Répéter les petits-déjeuners simples';

  @override
  String get planner_allergies_respected =>
      'Vos allergies et restrictions sont toujours respectées';

  @override
  String get planner_creating_body => 'Une semaine pensée pour vous';

  @override
  String get planner_preferences_checked => 'Préférences vérifiées';

  @override
  String get planner_balancing_nutrition =>
      'Équilibrage nutritionnel quotidien';

  @override
  String get planner_choosing_meals => 'Choix de repas pratiques';

  @override
  String get planner_preparing_grocery =>
      'Préparation de votre liste de courses';

  @override
  String get planner_generation_leave =>
      'Vous pouvez quitter cet écran. Votre plan continuera à se créer.';

  @override
  String get planner_cancel_generation => 'Continuer en arrière-plan';

  @override
  String get planner_week_contains => 'Cette semaine comprend';

  @override
  String get planner_under_30 => 'Moins de 30 min';

  @override
  String get planner_smart_leftovers => 'Restes intelligents';

  @override
  String get planner_plan_tab => 'Plan';

  @override
  String get planner_week_label => 'Semaine';

  @override
  String planner_meals_kcal_summary(Object calories, Object count) {
    return '$count repas · $calories kcal';
  }

  @override
  String get planner_adjust_day => 'Ajuster la journée';

  @override
  String get planner_view_grocery => 'Voir la liste de courses';

  @override
  String get planner_next_meal => 'Suivant';

  @override
  String get planner_log_meal => 'Enregistrer le repas';

  @override
  String get planner_meal_details => 'Détails du repas';

  @override
  String get planner_servings => 'Portions';

  @override
  String get planner_preparation => 'Préparation';

  @override
  String get planner_prep_ingredients => 'Préparez et mesurez les ingrédients.';

  @override
  String get planner_prep_cook =>
      'Faites cuire jusqu\'à ce que tout soit prêt.';

  @override
  String get planner_prep_combine =>
      'Assemblez, assaisonnez et ajustez au goût.';

  @override
  String get planner_prep_serve => 'Servez frais et dégustez.';

  @override
  String get planner_swap_meal => 'Changer le repas';

  @override
  String get planner_swap_different_cuisine => 'Autre cuisine';

  @override
  String get planner_swap_surprise => 'Surprenez-moi';

  @override
  String get planner_keep_calories => 'Garder des calories similaires';

  @override
  String get planner_keep_time => 'Garder le même temps de préparation';

  @override
  String get planner_keep_preferences => 'Respecter mes préférences';

  @override
  String get planner_only_meal_changes => 'Seul ce repas changera';

  @override
  String get planner_find_replacement => 'Trouver un remplacement';

  @override
  String planner_grocery_progress(Object checked, Object total) {
    return '$checked sur $total';
  }

  @override
  String get planner_filter_all => 'Tout';

  @override
  String get planner_filter_needed => 'Nécessaire';

  @override
  String get planner_filter_checked => 'Coché';

  @override
  String get planner_combined_quantities =>
      'Les quantités sont regroupées pour toute la semaine';

  @override
  String get planner_clear_checked => 'Effacer les éléments cochés';

  @override
  String get planner_shopping_mode => 'Mode courses';

  @override
  String get planner_unlock_title => 'Débloquez la planification hebdomadaire';

  @override
  String get planner_unlock_body =>
      'Consultez les 7 jours, changez les repas et utilisez une liste intelligente.';

  @override
  String get planner_one_day_preview => 'Votre aperçu d\'une journée';

  @override
  String get planner_locked_days => '6 jours supplémentaires prêts avec Pro';

  @override
  String get planner_unlock_pro => 'Débloquer avec Wazn Pro';

  @override
  String get pro_welcome_eyebrow => 'Tout est prêt';

  @override
  String get pro_welcome_title => 'Bienvenue sur Wazn Pro';

  @override
  String get pro_welcome_subtitle =>
      'Toutes les fonctions Pro sont prêtes pour vous.';

  @override
  String get pro_welcome_cta => 'Commencer à explorer';

  @override
  String get pro_restored_eyebrow => 'Bon retour';

  @override
  String get pro_restored_title => 'Pro restauré';

  @override
  String get sync_status_title => 'Synchronisation cloud';

  @override
  String sync_signed_in_as(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get sync_status_syncing => 'Synchronisation…';

  @override
  String sync_status_last(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get sync_status_never => 'Touchez pour synchroniser';

  @override
  String sync_status_pending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications en attente d’envoi',
      one: '1 modification en attente d’envoi',
    );
    return '$_temp0';
  }

  @override
  String get sync_status_failed =>
      'Échec de la synchronisation. Touchez pour réessayer';

  @override
  String get sync_status_done => 'Tout est synchronisé';

  @override
  String get update_available_title => 'Mise à jour disponible';

  @override
  String get update_available_message =>
      'Une nouvelle version de Wazn est disponible, avec des corrections et des améliorations.';

  @override
  String get update_now => 'Mettre à jour';

  @override
  String get update_later => 'Plus tard';

  @override
  String get settings_rate_app => 'Noter Wazn';

  @override
  String get settings_send_feedback => 'Envoyer un avis';

  @override
  String get feedback_email_subject => 'Avis sur Wazn';

  @override
  String feedback_email_copied(String email) {
    return 'Aucune app e-mail trouvée. Notre adresse a été copiée : $email';
  }

  @override
  String get pro_offer_title => 'Débloquez Wazn Pro';

  @override
  String get pro_offer_subtitle => 'Scannez chaque repas, sans limite.';

  @override
  String pro_offer_scans_used(int used, int limit) {
    return 'Vous avez utilisé $used scans gratuits sur $limit ce mois-ci';
  }

  @override
  String pro_offer_days_free(int days) {
    return '$days jours gratuits';
  }

  @override
  String get pro_offer_first_year => 'la première année';

  @override
  String get pro_offer_year => '/ an';

  @override
  String get pro_offer_month => '/ mois';

  @override
  String pro_offer_per_year(String price) {
    return '$price/an';
  }

  @override
  String pro_offer_per_month(String price) {
    return '$price/mois';
  }

  @override
  String pro_offer_approx_month(String price) {
    return '≈ $price/mois';
  }

  @override
  String pro_offer_claim(String percent) {
    return 'Profitez de -$percent %';
  }

  @override
  String get pro_offer_get_pro => 'Obtenir Wazn Pro';

  @override
  String get pro_offer_not_now => 'Pas maintenant';

  @override
  String pro_offer_ends_on(String date) {
    return 'L\'offre se termine le $date';
  }

  @override
  String get pro_offer_brand => 'WAZN PRO';

  @override
  String pro_offer_big_percent(String percent) {
    return '$percent %';
  }

  @override
  String get pro_offer_off => 'DE REMISE';

  @override
  String get pro_offer_off_first_year => 'sur votre première année de Wazn Pro';

  @override
  String get pro_offer_off_yearly => 'en payant à l\'année';

  @override
  String get pro_offer_paying_monthly => 'Au mois pendant un an';

  @override
  String get pro_offer_with_offer => 'Avec cette offre';

  @override
  String pro_offer_you_save(String amount) {
    return 'Vous économisez $amount';
  }

  @override
  String pro_offer_per_day(String price) {
    return 'Seulement $price par jour';
  }

  @override
  String get pro_offer_compare_title => 'Ce que vous obtenez';

  @override
  String get pro_offer_free => 'Gratuit';

  @override
  String get pro_offer_pro => 'PRO';

  @override
  String get pro_offer_row_scans => 'Scans photo';

  @override
  String get pro_offer_row_coach => 'Coach IA';

  @override
  String get pro_offer_row_planner => 'Planificateur';

  @override
  String get pro_offer_row_reports => 'Rapports hebdo';

  @override
  String get pro_offer_row_history => 'Historique';

  @override
  String pro_offer_scans_month(int count) {
    return '$count/mois';
  }

  @override
  String get pro_offer_unlimited => 'Illimité';

  @override
  String get pro_offer_limited => 'Limité';

  @override
  String pro_offer_days(int count) {
    return '$count jours';
  }

  @override
  String get pro_offer_full => 'Complet';

  @override
  String pro_offer_cta_intro(String intro, String price) {
    return '$intro la première année, puis $price/an';
  }

  @override
  String get scan_problem_offline_title => 'Pas de connexion internet';

  @override
  String get scan_problem_offline_body =>
      'Connectez-vous à internet et réessayez.';

  @override
  String get scan_problem_slow_title => 'Cela prend trop de temps';

  @override
  String get scan_problem_slow_body =>
      'Votre connexion est peut-être lente. Vérifiez-la et réessayez.';

  @override
  String get scan_problem_failed_title => 'Impossible d\'analyser cette photo';

  @override
  String get scan_problem_failed_body =>
      'Un problème est survenu de notre côté. Réessayez ou ajoutez le repas manuellement.';

  @override
  String get scan_problem_no_food_title => 'Aucun aliment trouvé';

  @override
  String get scan_problem_no_food_body =>
      'Nous n\'avons repéré aucun aliment sur cette photo. Reprenez-la avec le plat bien cadré, ou ajoutez-le manuellement.';

  @override
  String get scan_problem_image_title => 'Impossible d\'utiliser cette photo';

  @override
  String get scan_problem_image_body =>
      'Essayez une autre photo ou ajoutez le repas manuellement.';

  @override
  String get scan_problem_barcode_title => 'Produit introuvable';

  @override
  String get scan_problem_barcode_body =>
      'Ce code-barres n\'est pas encore dans notre base. Scannez-le à nouveau ou ajoutez l\'aliment manuellement.';

  @override
  String get scan_problem_scan_again => 'Scanner à nouveau';

  @override
  String get scan_problem_dismiss => 'OK';

  @override
  String get meal_save_failed =>
      'Impossible d\'enregistrer votre repas. Veuillez réessayer.';

  @override
  String get snap_camera_slow =>
      'L\'appareil photo met plus de temps que d\'habitude à démarrer.';

  @override
  String get snap_camera_permission =>
      'Wazn a besoin de l\'appareil photo pour scanner vos repas. Autorisez-le dans les réglages du téléphone.';

  @override
  String get snap_camera_unavailable =>
      'L\'appareil photo n\'a pas pu démarrer. Veuillez réessayer.';

  @override
  String get snap_open_settings => 'Ouvrir les réglages';

  @override
  String get log_meal_deleted => 'Repas supprimé';

  @override
  String get onboarding_pace_recommended => 'Recommandé';

  @override
  String get planner_regen_limit =>
      'Vous pouvez renouveler votre plan 3 fois par semaine. Réessayez dans quelques jours.';

  @override
  String get planner_week_ended_title => 'Le plan de cette semaine est terminé';

  @override
  String get planner_week_ended_body =>
      'Planifiez une nouvelle semaine pour garder le cap.';

  @override
  String get planner_week_ended_action => 'Planifier ma nouvelle semaine';

  @override
  String get planner_skip_light => 'À sauter ou très léger';

  @override
  String get coach_input_hint =>
      'Posez n\'importe quelle question à votre coach…';

  @override
  String get coach_input_locked => 'Passez à Pro pour continuer…';

  @override
  String get stats_range_7 => '7 derniers jours';

  @override
  String get stats_range_30 => '30 derniers jours';

  @override
  String get stats_avg_per_day => 'Calories par jour, en moyenne';

  @override
  String stats_under_target(int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString sous votre objectif';
  }

  @override
  String stats_over_target(int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString au-dessus de votre objectif';
  }

  @override
  String get stats_on_target => 'Sur votre objectif';

  @override
  String stats_logged_days(int logged, int days) {
    return 'Enregistré $logged jours sur $days';
  }

  @override
  String get stats_no_data_title => 'Rien d’enregistré sur cette période';

  @override
  String get stats_no_data_body =>
      'Scannez ou ajoutez un repas : vos moyennes, votre graphique et vos macros apparaîtront ici.';

  @override
  String get stats_target_line => 'Objectif';

  @override
  String get stats_days_logged_label => 'Jours enregistrés';

  @override
  String get stats_streak_label => 'Série';

  @override
  String stats_streak_days(int count) {
    return '$count d’affilée';
  }

  @override
  String get stats_macros_title => 'Macros face à l’objectif';

  @override
  String stats_macro_of_target(int value, int target) {
    final intl.NumberFormat valueNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);
    final intl.NumberFormat targetNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$valueString g sur $targetString g';
  }

  @override
  String get stats_weight_title => 'Poids';

  @override
  String stats_weight_since(int days) {
    return 'Sur $days jours';
  }

  @override
  String get stats_weight_one_entry =>
      'Une seule pesée pour l’instant — ajoutez-en une autre pour voir la tendance.';

  @override
  String get stats_chart_hint => 'Touchez un jour pour voir son total';

  @override
  String get stats_pro_range_locked => 'Les 30 jours sont réservés à Pro';

  @override
  String get stats_export => 'Partager en PDF';

  @override
  String get stats_pro_title => 'VOIR UN MOIS ENTIER';

  @override
  String get stats_pro_subtitle =>
      'Pro ouvre la vue sur 30 jours et permet de partager vos chiffres en PDF.';

  @override
  String get stats_pro_button => 'Débloquer 30 jours';

  @override
  String get voice_log_title => 'Saisie vocale';

  @override
  String get voice_heading => 'Décrivez ce que vous avez mangé';

  @override
  String get voice_subtitle =>
      'Parlez naturellement, puis vérifiez le texte avant l’analyse de votre repas.';

  @override
  String get voice_tap_to_speak => 'Appuyer pour parler';

  @override
  String get voice_listening => 'Écoute — appuyez pour arrêter';

  @override
  String get voice_transcript_label => 'Description du repas';

  @override
  String get voice_transcript_hint => 'Qu’avez-vous mangé ou bu ?';

  @override
  String get voice_example =>
      'Exemple : Deux œufs, une tartine et un café au lait';

  @override
  String get voice_privacy_note => 'Wazn n’enregistre pas votre audio.';

  @override
  String get voice_analyze => 'Analyser le repas';

  @override
  String get voice_analyzing => 'Analyse du repas…';

  @override
  String get voice_speak_again => 'Parler à nouveau';

  @override
  String get voice_no_speech =>
      'Je n’ai rien entendu. Réessayez ou saisissez votre repas.';

  @override
  String get voice_permission_denied =>
      'L’accès au micro est nécessaire. Vous pouvez toujours saisir votre repas.';

  @override
  String get voice_open_settings => 'Réglages';

  @override
  String get voice_unavailable =>
      'La reconnaissance vocale est indisponible. Vous pouvez toujours saisir votre repas.';

  @override
  String get voice_no_food =>
      'Aucun aliment n’a été trouvé. Vérifiez le texte et réessayez.';

  @override
  String get voice_analysis_failed =>
      'Wazn n’a pas pu analyser ce repas. Veuillez réessayer.';

  @override
  String get quick_add_title => 'Ajout rapide';

  @override
  String get quick_add_search => 'Rechercher un aliment';

  @override
  String get quick_add_for_you => 'Pour vous';

  @override
  String get quick_add_recent => 'Récents';

  @override
  String get quick_add_local => 'Locaux';

  @override
  String get quick_add_favorites => 'Favoris';

  @override
  String get quick_add_all => 'Tous';

  @override
  String get quick_add_see_all => 'Tout voir';

  @override
  String get quick_add_empty =>
      'Aucun aliment ne correspond à cette recherche.';

  @override
  String get quick_add_empty_favorites =>
      'Ajoutez des favoris pour les retrouver en un geste.';

  @override
  String get quick_add_region => 'Région alimentaire';

  @override
  String get quick_add_region_subtitle =>
      'Les aliments locaux apparaissent en premier. Vous pouvez modifier ce choix à tout moment.';

  @override
  String get quick_add_region_automatic => 'Automatique';

  @override
  String get quick_add_region_pakistan => 'Pakistan';

  @override
  String get quick_add_region_south_asian => 'Asie du Sud';

  @override
  String get quick_add_region_middle_eastern => 'Moyen-Orient';

  @override
  String get quick_add_region_gulf => 'Golfe';

  @override
  String get quick_add_region_east_asian => 'Asie de l’Est';

  @override
  String get quick_add_region_korean => 'Coréenne';

  @override
  String get quick_add_region_american => 'Américaine';

  @override
  String get quick_add_region_mediterranean => 'Méditerranéenne';

  @override
  String get quick_add_region_international => 'Internationale';

  @override
  String get quick_add_serving => 'Portion';

  @override
  String get quick_add_half_serving => '½ portion';

  @override
  String get quick_add_one_serving => '1 portion';

  @override
  String get quick_add_one_half_servings => '1½ portions';

  @override
  String get quick_add_two_servings => '2 portions';

  @override
  String quick_add_grams(int grams) {
    final intl.NumberFormat gramsNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String gramsString = gramsNumberFormat.format(grams);

    return '$gramsString g';
  }

  @override
  String quick_add_calories(int calories) {
    final intl.NumberFormat caloriesNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String caloriesString = caloriesNumberFormat.format(calories);

    return '$caloriesString kcal';
  }

  @override
  String get quick_add_add => 'Ajouter au journal';

  @override
  String quick_add_added(String food) {
    return '$food ajouté';
  }

  @override
  String get quick_add_undo => 'Annuler';

  @override
  String get quick_add_previous_portion => 'Votre portion habituelle';

  @override
  String get onb_welcome_title => 'Un plan calorique fait pour votre corps.';

  @override
  String get onb_welcome_body => 'Prêt en moins d\'une minute.';

  @override
  String get onb_section_goal => 'Votre objectif';

  @override
  String get onb_section_about => 'À propos de vous';

  @override
  String get onb_section_target => 'Votre cible';

  @override
  String get onb_section_plan => 'Votre plan';

  @override
  String get onb_q_goal => 'Quel est votre objectif ?';

  @override
  String get onb_q_sex => 'Quel est votre sexe ?';

  @override
  String get onb_q_age => 'Quel âge avez-vous ?';

  @override
  String get onb_age_years => 'ans';

  @override
  String get onb_q_height => 'Quelle est votre taille ?';

  @override
  String get onb_unit_ft => 'ft';

  @override
  String get onb_q_weight => 'Quel est votre poids actuel ?';

  @override
  String get onb_bmi => 'IMC';

  @override
  String get onb_bmi_below => 'Sous la plage saine';

  @override
  String get onb_bmi_healthy => 'Plage saine';

  @override
  String get onb_bmi_above => 'Au-dessus de la plage saine';

  @override
  String get onb_bmi_well_above => 'Bien au-dessus de la plage saine';

  @override
  String get onb_bmi_under_18 => 'Moins de 18 ans';

  @override
  String onb_bmi_range(String range) {
    return 'Plage saine : $range';
  }

  @override
  String get onb_bmi_teen =>
      'Les plages adultes ne s\'appliquent pas avant 18 ans.';

  @override
  String get onb_q_activity => 'Quel est votre niveau d\'activité ?';

  @override
  String get onb_act_sitting => 'Surtout assis';

  @override
  String get onb_act_sitting_hint => 'Travail de bureau';

  @override
  String get onb_act_light => 'Légèrement actif';

  @override
  String get onb_act_light_hint => 'Marche, exercice léger';

  @override
  String get onb_act_active => 'Actif';

  @override
  String get onb_act_active_hint => 'Sport 3 à 5 fois par semaine';

  @override
  String get onb_act_very => 'Très actif';

  @override
  String get onb_act_very_hint => 'Entraînement presque tous les jours';

  @override
  String get onb_q_target => 'Quel poids visez-vous ?';

  @override
  String get onb_q_target_gain => 'Jusqu\'à quel poids voulez-vous monter ?';

  @override
  String onb_target_lower(String weight) {
    return 'Choisissez moins de $weight.';
  }

  @override
  String onb_target_higher(String weight) {
    return 'Choisissez plus de $weight.';
  }

  @override
  String get onb_target_too_far => 'Trop loin de votre poids actuel.';

  @override
  String onb_target_already_below(String maintain) {
    return 'Vous êtes sous la plage saine. Choisissez plutôt $maintain.';
  }

  @override
  String onb_target_lowest(String weight) {
    return 'Cible saine minimale : $weight';
  }

  @override
  String get onb_target_milestone => 'Une bonne première étape.';

  @override
  String get onb_target_muscle =>
      'Au-dessus de la plage saine, normal avec du muscle.';

  @override
  String get onb_target_healthy => 'Dans la plage saine.';

  @override
  String get onb_q_pace => 'À quel rythme voulez-vous y arriver ?';

  @override
  String get onb_q_pace_gain => 'À quel rythme voulez-vous progresser ?';

  @override
  String onb_pace_per_week(String amount) {
    return '$amount par semaine';
  }

  @override
  String onb_pace_reach(String date) {
    return 'Atteint le $date';
  }

  @override
  String get onb_pace_adults_only => '18+';

  @override
  String get onb_pace_teen => 'Moins de 18 ans : rythme doux uniquement.';

  @override
  String onb_pace_kcal(String kcal) {
    return 'Environ $kcal kcal par jour';
  }

  @override
  String get onb_chart_today => 'Aujourd\'hui';

  @override
  String get onb_build_plan => 'Créer mon plan';

  @override
  String get onb_building_title => 'Création de votre plan';

  @override
  String get onb_building_needs => 'Vos besoins caloriques';

  @override
  String get onb_building_pace => 'Un rythme sûr';

  @override
  String get onb_building_macros => 'Vos macros';

  @override
  String get onb_plan_daily_target => 'Votre objectif quotidien';

  @override
  String get onb_plan_daily_guide => 'Votre repère quotidien';

  @override
  String get onb_plan_calories_a_day => 'calories par jour';

  @override
  String get onb_plan_maintenance => 'Maintien';

  @override
  String onb_plan_kcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get onb_plan_this_plan => 'Ce plan';

  @override
  String onb_plan_below(String kcal) {
    return '$kcal kcal en dessous';
  }

  @override
  String onb_plan_above(String kcal) {
    return '$kcal kcal au-dessus';
  }

  @override
  String get onb_plan_matches => 'Identique';

  @override
  String onb_plan_reach(String weight) {
    return 'Atteindre $weight';
  }

  @override
  String get onb_plan_stay => 'Rester autour de';

  @override
  String get onb_plan_change_later =>
      'Vous pouvez le modifier à tout moment dans les Réglages.';

  @override
  String get onb_plan_teen =>
      'Moins de 18 ans ? Parlez-en à un parent ou un médecin.';

  @override
  String get paywall_compare_free => 'Gratuit';

  @override
  String get paywall_compare_pro => 'Pro';

  @override
  String get paywall_row_scans => 'Scans de repas';

  @override
  String get paywall_row_meal_plans => 'Plans de repas';

  @override
  String get paywall_row_coach => 'Coach IA';

  @override
  String get paywall_row_photos => 'Photos de progrès';

  @override
  String get paywall_row_history => 'Historique';

  @override
  String paywall_free_scans_month(String count) {
    return '$count par mois';
  }

  @override
  String paywall_free_scans_left(String left, String limit) {
    return 'Il en reste $left sur $limit';
  }

  @override
  String get paywall_free_meal_plan => '1 jour';

  @override
  String get paywall_pro_meal_plan => 'Semaine complète';

  @override
  String get paywall_free_coach => '1 question par jour';

  @override
  String get paywall_pro_coach => 'À tout moment';

  @override
  String paywall_free_photos(String count) {
    return '$count bilans';
  }

  @override
  String paywall_free_history(String days) {
    return '$days derniers jours';
  }

  @override
  String get paywall_pro_history => 'Tout';

  @override
  String get paywall_see_everything => 'Voir tout ce qu’inclut Pro';

  @override
  String get paywall_everything_title => 'Tout ce qu’inclut Pro';

  @override
  String get paywall_all_scans_title => 'Scans illimités';

  @override
  String paywall_all_scans_detail(String count) {
    return 'Au lieu de $count par mois';
  }

  @override
  String get paywall_all_coach_title => 'Coach IA à tout moment';

  @override
  String get paywall_all_coach_detail => 'Au lieu d’une question par jour';

  @override
  String get paywall_all_plans_title => 'Plans de repas hebdomadaires';

  @override
  String get paywall_all_plans_detail =>
      'Avec une liste de courses prête, au lieu d’un jour';

  @override
  String get paywall_all_history_title => 'Historique complet et rapports';

  @override
  String paywall_all_history_detail(String days) {
    return 'Au lieu des $days derniers jours';
  }

  @override
  String get paywall_all_photos_title => 'Photos de progrès illimitées';

  @override
  String paywall_all_photos_detail(String count) {
    return 'Avec comparaisons côte à côte, au lieu de $count bilans';
  }

  @override
  String get paywall_plan_per_year => 'par an';

  @override
  String get paywall_plan_per_month => 'par mois';

  @override
  String paywall_plan_days_free(String days) {
    return '$days jours gratuits';
  }

  @override
  String paywall_plan_then(String price) {
    return 'puis $price';
  }

  @override
  String paywall_start_trial_days(String days) {
    return 'Commencer l’essai gratuit de $days jours';
  }

  @override
  String paywall_disclosure_trial_until_year(String date, String price) {
    return 'Gratuit jusqu’au $date, puis $price par an. Annulez avant et vous ne payez rien.';
  }

  @override
  String paywall_disclosure_trial_until_month(String date, String price) {
    return 'Gratuit jusqu’au $date, puis $price par mois. Annulez avant et vous ne payez rien.';
  }
}
