// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SnapCal';

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
  String get log_title => 'Journal Quotidien';

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
  String get log_add_manually => 'Ajouter Manuellement';

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
      'Votre coach SnapCal est prêt à vous aider avec des recettes, des objectifs et des conseils en nutrition.';

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
  String get premium_welcome => 'Bienvenue sur SnapCal Pro ! 🎉';

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
  String get sync_email => 'Se connecter par Email';

  @override
  String get sync_skip => 'Ignorer pour l\'instant';

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
  String get notif_meal_reminders_channel_description =>
      'Rappels pour suivre votre nutrition quotidienne.';

  @override
  String get notif_daily_motivation_channel => 'Motivation quotidienne';

  @override
  String get notif_daily_motivation_channel_description =>
      'Motivation nutritionnelle quotidienne et douce de SnapCal.';

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
  String get auth_footer_new => 'Nouveau sur SnapCal ? ';

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
  String get planner_unlock_week => 'Débloquer la semaine complète';

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
  String get settings_core_config => 'Configuration de base';

  @override
  String get settings_data_security => 'Données et sécurité';

  @override
  String get settings_information => 'Informations';

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
  String get report_failed => 'Échec de la génération du rapport';

  @override
  String get paywall_welcome => 'Bienvenue sur SnapCal Pro ! 🎉';

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
  String paywall_trial_reminder(Object day) {
    return 'Jour $day';
  }

  @override
  String get paywall_trial_reminder_desc =>
      'Nous vous rappelons la fin de l\'essai.';

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
  String get settings_terms_desc => 'Conditions générales';

  @override
  String get settings_about_snapcal => 'À propos de SnapCal';

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
  String onboarding_step(int current, int total) {
    return 'ÉTAPE $current SUR $total';
  }

  @override
  String get onboarding_get_started => 'Commencer';

  @override
  String get onboarding_start_journey => 'Démarrer mon parcours';

  @override
  String get onboarding_continue => 'Continuer';

  @override
  String get onboarding_welcome_title =>
      'Votre but.\nVos calories.\nVotre rythme.';

  @override
  String get onboarding_welcome_body =>
      'Répondez à quelques questions pour fixer votre cible.';

  @override
  String get onboarding_basic_intro_eyebrow => 'DÉTAILS PERSONNELS';

  @override
  String get onboarding_basic_intro_title => 'Fixez vos métriques de base.';

  @override
  String get onboarding_basic_intro_body =>
      'Utilisé pour calculer votre métabolisme (RMR).';

  @override
  String get onboarding_age => 'Âge';

  @override
  String get onboarding_age_suffix => 'ans';

  @override
  String get onboarding_gender => 'Sexe';

  @override
  String get onboarding_male => 'Homme';

  @override
  String get onboarding_female => 'Femme';

  @override
  String get onboarding_height => 'Taille';

  @override
  String get onboarding_weight_intro_eyebrow => 'STATUT ACTUEL';

  @override
  String get onboarding_weight_intro_title =>
      'Quel est votre poids aujourd\'hui ?';

  @override
  String get onboarding_weight_intro_body =>
      'Aide à comprendre votre point de départ.';

  @override
  String get onboarding_weight_footer =>
      'Sans jugement. Tout commence par un chiffre honnête.';

  @override
  String get onboarding_target_intro_eyebrow => 'LA CIBLE';

  @override
  String get onboarding_target_intro_title => 'Quel est votre poids cible ?';

  @override
  String get onboarding_target_intro_body =>
      'Nous ajusterons vos calories pour l\'atteindre.';

  @override
  String get onboarding_target_maintain_title => 'Maintenir le poids';

  @override
  String get onboarding_target_maintain_body =>
      'Plan pour stabiliser votre poids.';

  @override
  String get onboarding_timeline => 'Délai cible';

  @override
  String onboarding_months(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mois',
      one: 'Mois',
    );
    return '$count $_temp0';
  }

  @override
  String get onboarding_activity_eyebrow => 'MODE DE VIE';

  @override
  String get onboarding_activity_title => 'Quel est votre niveau d\'activité ?';

  @override
  String get onboarding_activity_body => 'Facteur clé pour votre dépense.';

  @override
  String get onboarding_activity_sedentary => 'Sédentaire';

  @override
  String get onboarding_activity_sedentary_desc => 'Bureau, peu d\'exercice';

  @override
  String get onboarding_activity_lightly => 'Légèrement actif';

  @override
  String get onboarding_activity_lightly_desc =>
      '1-3 jours d\'exercice/semaine';

  @override
  String get onboarding_activity_moderately => 'Modérément actif';

  @override
  String get onboarding_activity_moderately_desc =>
      '3-5 jours d\'exercice/semaine';

  @override
  String get onboarding_activity_active => 'Très actif';

  @override
  String get onboarding_activity_active_desc => '3-5 jours/semaine';

  @override
  String get onboarding_result_eyebrow => 'VOTRE PLAN';

  @override
  String get onboarding_result_title => 'Votre cible est prête.';

  @override
  String get onboarding_result_kcal_day => 'kcal / jour';

  @override
  String onboarding_result_reach_by(String date) {
    return 'Objectif atteint le $date';
  }

  @override
  String onboarding_result_pace(String pace, String unit) {
    return 'Rythme : $pace $unit / semaine';
  }

  @override
  String get onboarding_error_age =>
      'Veuillez entrer un âge valide entre 13 et 100 ans.';

  @override
  String get onboarding_error_height =>
      'Veuillez entrer une taille réaliste pour un calcul précis.';

  @override
  String get onboarding_error_weight =>
      'Veuillez entrer votre poids actuel pour commencer.';

  @override
  String get onboarding_error_goal_weight =>
      'Veuillez entrer votre poids cible réaliste.';

  @override
  String get onboarding_error_timeline =>
      'Veuillez ajuster votre délai pour un plan valide.';

  @override
  String get onboarding_error_generic => 'Échec de création du plan.';

  @override
  String get onboarding_result_loading_eyebrow => 'Résultat IA';

  @override
  String get onboarding_result_loading_title => 'Calcul de votre cible.';

  @override
  String get onboarding_result_loading_body =>
      'Combinaison des métriques en cours.';

  @override
  String get onboarding_result_calibrating => 'Calibration de votre cible...';

  @override
  String get onboarding_result_error_eyebrow => 'ERREUR CALCUL';

  @override
  String get onboarding_result_error_title => 'Échec du plan.';

  @override
  String get onboarding_result_error_body => 'Réessayez la dernière étape.';

  @override
  String get onboarding_result_success_eyebrow => 'CALIBRATION IA FINIE';

  @override
  String get onboarding_result_success_title => 'Cible prête.';

  @override
  String get onboarding_result_success_body =>
      'Chiffre personnalisé pour vous.';

  @override
  String get onboarding_result_minor_warning =>
      'Consultez un professionnel de santé avant d\'entamer une restriction calorique.';

  @override
  String get onboarding_result_daily_calories => 'CALORIES QUOTIDIENNES';

  @override
  String get onboarding_result_strategy => 'Stratégie';

  @override
  String get onboarding_result_recommendation => 'Recommandation';

  @override
  String get onboarding_activity_desk_life => 'Vie de bureau';

  @override
  String get onboarding_activity_desk_life_desc => 'Peu ou pas d\'exercice';

  @override
  String get onboarding_activity_light_mover => 'Bouge un peu';

  @override
  String get onboarding_activity_light_mover_desc => '1-3 jours/semaine';

  @override
  String get onboarding_activity_active_title => 'Actif';

  @override
  String get onboarding_activity_athlete => 'Athlète';

  @override
  String get onboarding_activity_athlete_desc => '6-7 jours/semaine';

  @override
  String get onboarding_activity_footer => 'Actif sélectionné par défaut.';

  @override
  String get onboarding_feature_target => 'Cible calorie perso';

  @override
  String get onboarding_feature_macros => 'Répartition macros';

  @override
  String get onboarding_feature_insight => 'Analyse IA';

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
  String get settings_member => 'Membre SnapCal';

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
  String get settings_about_app => 'À propos de SnapCal';

  @override
  String get settings_legalese => '© 2026 SnapCal. Tous droits réservés.';

  @override
  String get onboarding_result_maintain => 'Maintenir le poids actuel';

  @override
  String onboarding_result_weekly_rate(String rate) {
    return '~$rate kg / semaine';
  }

  @override
  String get error_connection_title => 'Problème de connexion';

  @override
  String get error_connection_body =>
      'Impossible d\'initialiser SnapCal. Veuillez vérifier vos données ou le Wi-Fi.';

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
      'Mon parcours de transformation SnapCal ! 🚀';

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
      'Découvrez mon résumé nutritionnel hebdomadaire de SnapCal ! 📊';

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
  String get report_prompt_btn => 'Débloquer le rapport hebdomadaire';

  @override
  String get scan_overlay_scanning => 'ANALYSE PAR VISION IA';

  @override
  String get scan_overlay_desc =>
      'Détection des ingrédients et calcul de la densité nutritionnelle avec Gemini...';

  @override
  String get scan_overlay_manual => 'SAISIR MANUELLEMENT';

  @override
  String get report_card_title => 'RAPPORT DE PROGRÈS HEBDOMADAIRE';

  @override
  String get report_card_subtitle =>
      'Découvrez pourquoi certains jours ont dépassé l\'objectif et obtenez des suggestions personnalisées pour y remédier.';

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
  String get home_welcome_guest => 'Bienvenue sur SnapCal';

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
  String get paywall_cancel_anytime =>
      'Annulez à tout moment. Sans engagement.';

  @override
  String get paywall_terms_conditions => 'Conditions générales';

  @override
  String get paywall_trial_7_day => 'Essai de 7 jours';

  @override
  String get paywall_scan_limit_subtitle =>
      'Vous avez utilisé 3/3 scans gratuits aujourd\'hui. Débloquez les scans alimentaires IA illimités et le détail instantané des calories.';

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
      'Ce rapport a été généré automatiquement par SnapCal AI.';

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
  String get paywall_unlock_snapcal_pro => 'Débloquer SnapCal Pro';

  @override
  String get paywall_barcode_title => 'Débloquer le scanner de codes-barres';

  @override
  String get paywall_barcode_subtitle =>
      'Enregistrez instantanément les aliments emballés en scannant leurs codes-barres';

  @override
  String get paywall_free_scans_used_title =>
      'Vous avez utilisé 3/3 scans gratuits aujourd\'hui';

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
    return 'Objectif : $steps pas';
  }

  @override
  String get activity_unlock_pro_title =>
      'Débloquer les fonctions Pro d\'activité';

  @override
  String get activity_unlock_pro_subtitle =>
      'Passez à Pro pour débloquer l\'ajustement dynamique de l\'objectif calorique par les pas, les séries hebdomadaires, les calories d\'entraînement manuel, le score d\'activité et les insights.';

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
    return 'Vous avez fait en moyenne $steps pas cette semaine et atteignez votre objectif.';
  }

  @override
  String activity_insight_goal_gap(int steps) {
    return 'Vous avez fait en moyenne $steps pas cette semaine. Une courte marche peut aider à combler l\'écart.';
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
  String get activity_workout_calories => 'Calories d\'entraînement';

  @override
  String get activity_score => 'Score d\'activité';

  @override
  String get common_days => 'jours';
}
