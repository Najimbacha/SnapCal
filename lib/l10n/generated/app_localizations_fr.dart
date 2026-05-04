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
  String get settings_cloud_sync_desc => 'Connectez-vous pour sauvegarder';

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
}
