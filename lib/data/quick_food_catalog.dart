import 'dart:ui' as ui;

import 'models/quick_food.dart';

/// Small, reviewed catalogue for the instant-log surface.
///
/// Every nutrition ID and per-100 g value mirrors the curated FDB rows in
/// `backend/data/nutrition_db.json`. Keeping this first download-free pack
/// intentionally small makes the Log screen immediate and available offline;
/// the IDs let a future version refresh it from the server without changing
/// existing meal history.
class QuickFoodCatalog {
  QuickFoodCatalog._();

  static const foods = <QuickFood>[
    // Familiar international staples.
    QuickFood(
      nutritionId: 'FDB_000363',
      name: 'Cooked egg',
      caloriesPer100g: 155,
      proteinPer100g: 13,
      carbsPer100g: 1.1,
      fatPer100g: 11,
      defaultServingG: 50,
      regions: {'international'},
      mealTypes: {'Breakfast', 'Snack'},
      localizedNames: {
        'ar': 'بيض مطبوخ',
        'es': 'Huevo cocido',
        'fr': 'Œuf cuit',
      },
      aliases: ['boiled egg', 'fried egg'],
    ),
    QuickFood(
      nutritionId: 'FDB_000357',
      name: 'Greek yogurt',
      caloriesPer100g: 97,
      proteinPer100g: 9,
      carbsPer100g: 3.6,
      fatPer100g: 5,
      defaultServingG: 170,
      regions: {'international'},
      mealTypes: {'Breakfast', 'Snack'},
      localizedNames: {
        'ar': 'زبادي يوناني',
        'es': 'Yogur griego',
        'fr': 'Yaourt grec',
      },
    ),
    QuickFood(
      nutritionId: 'FDB_000003',
      name: 'Roasted chicken breast',
      caloriesPer100g: 165,
      proteinPer100g: 31,
      carbsPer100g: 0,
      fatPer100g: 3.57,
      defaultServingG: 150,
      regions: {'international'},
      localizedNames: {
        'ar': 'صدر دجاج مشوي',
        'es': 'Pechuga de pollo asada',
        'fr': 'Blanc de poulet rôti',
      },
      aliases: ['grilled chicken'],
    ),
    QuickFood(
      nutritionId: 'FDB_000308',
      name: 'Couscous',
      caloriesPer100g: 112,
      proteinPer100g: 3.8,
      carbsPer100g: 23,
      fatPer100g: 0.2,
      defaultServingG: 180,
      regions: {'international', 'mediterranean'},
      localizedNames: {'ar': 'كسكس', 'es': 'Cuscús', 'fr': 'Couscous'},
    ),

    // Pakistan and South Asia.
    QuickFood(
      nutritionId: 'FDB_000531',
      name: 'Chicken curry',
      caloriesPer100g: 170,
      proteinPer100g: 18,
      carbsPer100g: 7,
      fatPer100g: 8,
      defaultServingG: 250,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'كاري الدجاج',
        'es': 'Pollo al curry',
        'fr': 'Curry de poulet',
      },
      countries: {'PK', 'IN', 'BD'},
    ),
    QuickFood(
      nutritionId: 'FDB_000532',
      name: 'Chicken tikka masala',
      caloriesPer100g: 180,
      proteinPer100g: 16,
      carbsPer100g: 8,
      fatPer100g: 10,
      defaultServingG: 250,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'دجاج تكا ماسالا',
        'es': 'Pollo tikka masala',
        'fr': 'Poulet tikka masala',
      },
      countries: {'PK', 'IN', 'GB'},
    ),
    QuickFood(
      nutritionId: 'FDB_000533',
      name: 'Chicken biryani',
      caloriesPer100g: 195,
      proteinPer100g: 8,
      carbsPer100g: 28,
      fatPer100g: 6,
      defaultServingG: 300,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'برياني دجاج',
        'es': 'Biryani de pollo',
        'fr': 'Biryani au poulet',
      },
      countries: {'PK', 'IN', 'BD'},
    ),
    QuickFood(
      nutritionId: 'FDB_000534',
      name: 'Dal',
      caloriesPer100g: 116,
      proteinPer100g: 9,
      carbsPer100g: 20,
      fatPer100g: 0.4,
      defaultServingG: 220,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'دال بالعدس',
        'es': 'Dal de lentejas',
        'fr': 'Dal de lentilles',
      },
      countries: {'PK', 'IN', 'BD'},
      aliases: ['daal', 'lentil curry'],
    ),
    QuickFood(
      nutritionId: 'FDB_000570',
      name: 'Garlic naan',
      caloriesPer100g: 262,
      proteinPer100g: 8,
      carbsPer100g: 45,
      fatPer100g: 6,
      defaultServingG: 100,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'خبز نان بالثوم',
        'es': 'Naan de ajo',
        'fr': 'Naan à l\'ail',
      },
      countries: {'PK', 'IN'},
    ),
    QuickFood(
      nutritionId: 'FDB_000571',
      name: 'Vegetable samosa',
      caloriesPer100g: 260,
      proteinPer100g: 5,
      carbsPer100g: 32,
      fatPer100g: 13,
      defaultServingG: 75,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'سمبوسة خضار',
        'es': 'Samosa de verduras',
        'fr': 'Samoussa aux légumes',
      },
      countries: {'PK', 'IN', 'BD'},
    ),
    QuickFood(
      nutritionId: 'FDB_000572',
      name: 'Tandoori chicken',
      caloriesPer100g: 190,
      proteinPer100g: 23,
      carbsPer100g: 3,
      fatPer100g: 10,
      defaultServingG: 200,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'دجاج تندوري',
        'es': 'Pollo tandoori',
        'fr': 'Poulet tandoori',
      },
      countries: {'PK', 'IN'},
    ),
    QuickFood(
      nutritionId: 'FDB_000573',
      name: 'Butter chicken',
      caloriesPer100g: 200,
      proteinPer100g: 18,
      carbsPer100g: 8,
      fatPer100g: 12,
      defaultServingG: 250,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'دجاج بالزبدة',
        'es': 'Pollo a la mantequilla',
        'fr': 'Poulet au beurre',
      },
      countries: {'PK', 'IN'},
    ),
    QuickFood(
      nutritionId: 'FDB_000574',
      name: 'Palak paneer',
      caloriesPer100g: 120,
      proteinPer100g: 8,
      carbsPer100g: 6,
      fatPer100g: 8,
      defaultServingG: 220,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'بالاك بانير (سبانخ بالجبن)',
        'es': 'Palak paneer (espinacas con queso)',
        'fr': 'Palak paneer (épinards au fromage)',
      },
      countries: {'PK', 'IN'},
    ),
    QuickFood(
      nutritionId: 'FDB_000575',
      name: 'Chana masala',
      caloriesPer100g: 140,
      proteinPer100g: 7,
      carbsPer100g: 20,
      fatPer100g: 4,
      defaultServingG: 220,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'حمص ماسالا',
        'es': 'Chana masala (garbanzos al curry)',
        'fr': 'Chana masala (pois chiches au curry)',
      },
      countries: {'PK', 'IN'},
    ),
    QuickFood(
      nutritionId: 'USDA_171844',
      name: 'Roti',
      caloriesPer100g: 297,
      proteinPer100g: 11.2,
      carbsPer100g: 46.4,
      fatPer100g: 7.45,
      defaultServingG: 50,
      regions: {'south_asian'},
      localizedNames: {
        'ar': 'خبز روتي',
        'es': 'Roti (pan plano)',
        'fr': 'Roti (pain plat)',
      },
      countries: {'PK', 'IN', 'BD'},
      aliases: ['chapati'],
    ),

    // Middle East and the Gulf.
    QuickFood(
      nutritionId: 'FDB_000545',
      name: 'Falafel',
      caloriesPer100g: 333,
      proteinPer100g: 13,
      carbsPer100g: 32,
      fatPer100g: 18,
      defaultServingG: 100,
      regions: {'middle_eastern'},
      localizedNames: {'ar': 'فلافل', 'es': 'Falafel', 'fr': 'Falafels'},
      countries: {'SA', 'AE', 'EG', 'JO', 'LB'},
    ),
    QuickFood(
      nutritionId: 'FDB_000546',
      name: 'Chicken shawarma',
      caloriesPer100g: 193,
      proteinPer100g: 18,
      carbsPer100g: 22,
      fatPer100g: 5,
      defaultServingG: 220,
      regions: {'middle_eastern'},
      localizedNames: {
        'ar': 'شاورما دجاج',
        'es': 'Shawarma de pollo',
        'fr': 'Chawarma au poulet',
      },
      countries: {'SA', 'AE', 'JO', 'LB'},
    ),
    QuickFood(
      nutritionId: 'FDB_000547',
      name: 'Grilled kebab',
      caloriesPer100g: 210,
      proteinPer100g: 22,
      carbsPer100g: 3,
      fatPer100g: 12,
      defaultServingG: 180,
      regions: {'middle_eastern'},
      localizedNames: {
        'ar': 'كباب مشوي',
        'es': 'Kebab a la parrilla',
        'fr': 'Kebab grillé',
      },
      countries: {'SA', 'AE', 'TR', 'PK'},
    ),
    QuickFood(
      nutritionId: 'FDB_000548',
      name: 'Hummus with pita',
      caloriesPer100g: 220,
      proteinPer100g: 8,
      carbsPer100g: 30,
      fatPer100g: 9,
      defaultServingG: 180,
      regions: {'middle_eastern', 'mediterranean'},
      localizedNames: {
        'ar': 'حمص مع خبز عربي',
        'es': 'Hummus con pan pita',
        'fr': 'Houmous et pain pita',
      },
    ),
    QuickFood(
      nutritionId: 'FDB_000549',
      name: 'Baba ganoush',
      caloriesPer100g: 78,
      proteinPer100g: 1.5,
      carbsPer100g: 5,
      fatPer100g: 6.2,
      defaultServingG: 150,
      regions: {'middle_eastern', 'mediterranean'},
      localizedNames: {
        'ar': 'بابا غنوج',
        'es': 'Baba ganoush',
        'fr': 'Baba ghanoush',
      },
    ),
    QuickFood(
      nutritionId: 'FDB_000577',
      name: 'Chicken kabsa',
      caloriesPer100g: 200,
      proteinPer100g: 12,
      carbsPer100g: 25,
      fatPer100g: 6,
      defaultServingG: 320,
      regions: {'middle_eastern'},
      localizedNames: {
        'ar': 'كبسة دجاج',
        'es': 'Kabsa de pollo',
        'fr': 'Kabsa au poulet',
      },
      countries: {'SA', 'KW', 'QA', 'BH'},
    ),
    QuickFood(
      nutritionId: 'FDB_000578',
      name: 'Chicken mandi',
      caloriesPer100g: 210,
      proteinPer100g: 14,
      carbsPer100g: 22,
      fatPer100g: 7,
      defaultServingG: 320,
      regions: {'middle_eastern'},
      localizedNames: {
        'ar': 'مندي دجاج',
        'es': 'Mandi de pollo',
        'fr': 'Mandi au poulet',
      },
      countries: {'SA', 'YE', 'AE'},
    ),
    QuickFood(
      nutritionId: 'FDB_000579',
      name: 'Koshari',
      caloriesPer100g: 160,
      proteinPer100g: 6,
      carbsPer100g: 28,
      fatPer100g: 3,
      defaultServingG: 300,
      regions: {'middle_eastern'},
      localizedNames: {'ar': 'كشري', 'es': 'Koshari', 'fr': 'Koshari'},
      countries: {'EG'},
    ),
    QuickFood(
      nutritionId: 'FDB_000580',
      name: 'Stuffed grape leaves',
      caloriesPer100g: 130,
      proteinPer100g: 4,
      carbsPer100g: 18,
      fatPer100g: 5,
      defaultServingG: 160,
      regions: {'middle_eastern', 'mediterranean'},
      localizedNames: {
        'ar': 'ورق عنب',
        'es': 'Hojas de parra rellenas',
        'fr': 'Feuilles de vigne farcies',
      },
      aliases: ['dolma'],
    ),
    QuickFood(
      nutritionId: 'FDB_000581',
      name: 'Tabbouleh',
      caloriesPer100g: 75,
      proteinPer100g: 2,
      carbsPer100g: 12,
      fatPer100g: 3,
      defaultServingG: 180,
      regions: {'middle_eastern', 'mediterranean'},
      localizedNames: {'ar': 'تبولة', 'es': 'Tabulé', 'fr': 'Taboulé'},
    ),
    QuickFood(
      nutritionId: 'FDB_000582',
      name: 'Fattoush salad',
      caloriesPer100g: 85,
      proteinPer100g: 2,
      carbsPer100g: 10,
      fatPer100g: 5,
      defaultServingG: 200,
      regions: {'middle_eastern', 'mediterranean'},
      localizedNames: {
        'ar': 'سلطة فتوش',
        'es': 'Ensalada fattoush',
        'fr': 'Salade fattouche',
      },
    ),

    // East Asia.
    QuickFood(
      nutritionId: 'FDB_000535',
      name: 'Salmon sushi roll',
      caloriesPer100g: 142,
      proteinPer100g: 6,
      carbsPer100g: 26,
      fatPer100g: 2,
      defaultServingG: 180,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'رول سوشي سلمون',
        'es': 'Rollo de sushi de salmón',
        'fr': 'Maki au saumon',
      },
      countries: {'JP'},
    ),
    QuickFood(
      nutritionId: 'FDB_000537',
      name: 'Tonkotsu ramen',
      caloriesPer100g: 121,
      proteinPer100g: 5,
      carbsPer100g: 14,
      fatPer100g: 5.5,
      defaultServingG: 500,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'رامن تونكوتسو',
        'es': 'Ramen tonkotsu',
        'fr': 'Ramen tonkotsu',
      },
      countries: {'JP'},
    ),
    QuickFood(
      nutritionId: 'FDB_000538',
      name: 'Fried rice',
      caloriesPer100g: 168,
      proteinPer100g: 5,
      carbsPer100g: 26,
      fatPer100g: 5,
      defaultServingG: 250,
      regions: {'east_asian'},
      localizedNames: {'ar': 'أرز مقلي', 'es': 'Arroz frito', 'fr': 'Riz frit'},
      countries: {'CN', 'SG'},
    ),
    QuickFood(
      nutritionId: 'FDB_000539',
      name: 'Chow mein',
      caloriesPer100g: 162,
      proteinPer100g: 6,
      carbsPer100g: 24,
      fatPer100g: 5,
      defaultServingG: 280,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'تشاو مين (نودلز مقلية)',
        'es': 'Chow mein (fideos salteados)',
        'fr': 'Chow mein (nouilles sautées)',
      },
      countries: {'CN'},
    ),
    QuickFood(
      nutritionId: 'FDB_000541',
      name: 'Steamed dumplings',
      caloriesPer100g: 111,
      proteinPer100g: 6,
      carbsPer100g: 17,
      fatPer100g: 2.5,
      defaultServingG: 180,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'زلابية على البخار',
        'es': 'Dumplings al vapor',
        'fr': 'Raviolis vapeur',
      },
      countries: {'CN', 'KR', 'JP'},
    ),
    QuickFood(
      nutritionId: 'FDB_000559',
      name: 'Kimchi',
      caloriesPer100g: 24,
      proteinPer100g: 1.1,
      carbsPer100g: 4,
      fatPer100g: 0.5,
      defaultServingG: 80,
      regions: {'east_asian'},
      localizedNames: {'ar': 'كيمتشي', 'es': 'Kimchi', 'fr': 'Kimchi'},
      countries: {'KR'},
    ),
    QuickFood(
      nutritionId: 'FDB_000560',
      name: 'Bibimbap',
      caloriesPer100g: 175,
      proteinPer100g: 7,
      carbsPer100g: 30,
      fatPer100g: 3.5,
      defaultServingG: 350,
      regions: {'east_asian'},
      localizedNames: {'ar': 'بيبيمباب', 'es': 'Bibimbap', 'fr': 'Bibimbap'},
      countries: {'KR'},
    ),
    QuickFood(
      nutritionId: 'FDB_000561',
      name: 'Teriyaki chicken',
      caloriesPer100g: 175,
      proteinPer100g: 16,
      carbsPer100g: 12,
      fatPer100g: 7,
      defaultServingG: 220,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'دجاج ترياكي',
        'es': 'Pollo teriyaki',
        'fr': 'Poulet teriyaki',
      },
      countries: {'JP'},
    ),
    QuickFood(
      nutritionId: 'FDB_000563',
      name: 'Miso soup',
      caloriesPer100g: 36,
      proteinPer100g: 2.5,
      carbsPer100g: 4,
      fatPer100g: 1.1,
      defaultServingG: 250,
      regions: {'east_asian'},
      localizedNames: {
        'ar': 'حساء ميسو',
        'es': 'Sopa de miso',
        'fr': 'Soupe miso',
      },
      countries: {'JP'},
    ),

    // North America.
    QuickFood(
      nutritionId: 'FDB_000481',
      name: 'Cheese pizza',
      caloriesPer100g: 266,
      proteinPer100g: 11,
      carbsPer100g: 33,
      fatPer100g: 10,
      defaultServingG: 120,
      regions: {'american'},
      localizedNames: {
        'ar': 'بيتزا بالجبن',
        'es': 'Pizza de queso',
        'fr': 'Pizza au fromage',
      },
    ),
    QuickFood(
      nutritionId: 'FDB_000483',
      name: 'Hamburger',
      caloriesPer100g: 250,
      proteinPer100g: 13,
      carbsPer100g: 30,
      fatPer100g: 9,
      defaultServingG: 180,
      regions: {'american'},
      localizedNames: {'ar': 'همبرغر', 'es': 'Hamburguesa', 'fr': 'Hamburger'},
      countries: {'US', 'CA'},
    ),
    QuickFood(
      nutritionId: 'FDB_000489',
      name: 'Beef taco',
      caloriesPer100g: 226,
      proteinPer100g: 10,
      carbsPer100g: 20,
      fatPer100g: 12,
      defaultServingG: 100,
      regions: {'american'},
      localizedNames: {
        'ar': 'تاكو باللحم',
        'es': 'Taco de carne',
        'fr': 'Taco au bœuf',
      },
      countries: {'US', 'MX'},
    ),
    QuickFood(
      nutritionId: 'FDB_000490',
      name: 'Beef burrito',
      caloriesPer100g: 224,
      proteinPer100g: 10,
      carbsPer100g: 27,
      fatPer100g: 9,
      defaultServingG: 250,
      regions: {'american'},
      localizedNames: {
        'ar': 'بوريتو باللحم',
        'es': 'Burrito de carne',
        'fr': 'Burrito au bœuf',
      },
      countries: {'US', 'MX'},
    ),

    // Mediterranean and southern Europe.
    QuickFood(
      nutritionId: 'FDB_000550',
      name: 'Paella',
      caloriesPer100g: 150,
      proteinPer100g: 8,
      carbsPer100g: 22,
      fatPer100g: 3.5,
      defaultServingG: 300,
      regions: {'mediterranean'},
      localizedNames: {'ar': 'باييلا', 'es': 'Paella', 'fr': 'Paella'},
      countries: {'ES'},
    ),
    QuickFood(
      nutritionId: 'FDB_000551',
      name: 'Risotto',
      caloriesPer100g: 130,
      proteinPer100g: 3.5,
      carbsPer100g: 22,
      fatPer100g: 3.5,
      defaultServingG: 280,
      regions: {'mediterranean'},
      localizedNames: {'ar': 'ريزوتو', 'es': 'Risotto', 'fr': 'Risotto'},
      countries: {'IT'},
    ),
    QuickFood(
      nutritionId: 'FDB_000552',
      name: 'Pasta carbonara',
      caloriesPer100g: 215,
      proteinPer100g: 9,
      carbsPer100g: 22,
      fatPer100g: 10,
      defaultServingG: 280,
      regions: {'mediterranean'},
      localizedNames: {
        'ar': 'باستا كاربونارا',
        'es': 'Pasta carbonara',
        'fr': 'Pâtes carbonara',
      },
      countries: {'IT'},
    ),
    QuickFood(
      nutritionId: 'FDB_000553',
      name: 'Pasta bolognese',
      caloriesPer100g: 135,
      proteinPer100g: 8,
      carbsPer100g: 18,
      fatPer100g: 3.5,
      defaultServingG: 300,
      regions: {'mediterranean'},
      localizedNames: {
        'ar': 'باستا بولونيز',
        'es': 'Pasta a la boloñesa',
        'fr': 'Pâtes bolognaise',
      },
      countries: {'IT'},
    ),
    QuickFood(
      nutritionId: 'FDB_000554',
      name: 'Lasagna',
      caloriesPer100g: 175,
      proteinPer100g: 10,
      carbsPer100g: 17,
      fatPer100g: 8,
      defaultServingG: 300,
      regions: {'mediterranean'},
      localizedNames: {'ar': 'لازانيا', 'es': 'Lasaña', 'fr': 'Lasagnes'},
      countries: {'IT'},
    ),
    QuickFood(
      nutritionId: 'FDB_000555',
      name: 'Margherita pizza',
      caloriesPer100g: 238,
      proteinPer100g: 10,
      carbsPer100g: 30,
      fatPer100g: 9,
      defaultServingG: 120,
      regions: {'mediterranean'},
      localizedNames: {
        'ar': 'بيتزا مارغريتا',
        'es': 'Pizza margarita',
        'fr': 'Pizza margherita',
      },
      countries: {'IT'},
    ),
  ];

  static String deviceCountryCode() =>
      ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? '';

  static String automaticRegion([String? countryCode]) {
    final code = (countryCode ?? deviceCountryCode()).toUpperCase();
    if ({'PK', 'IN', 'BD', 'LK', 'NP'}.contains(code)) return 'south_asian';
    if ({
      'SA',
      'AE',
      'QA',
      'KW',
      'BH',
      'OM',
      'YE',
      'JO',
      'LB',
      'EG',
      'IQ',
    }.contains(code)) {
      return 'middle_eastern';
    }
    if ({'CN', 'HK', 'TW', 'JP', 'KR', 'SG', 'TH', 'VN'}.contains(code)) {
      return 'east_asian';
    }
    if ({'US', 'CA', 'MX'}.contains(code)) return 'american';
    if ({'ES', 'IT', 'GR', 'TR', 'MA', 'TN'}.contains(code)) {
      return 'mediterranean';
    }
    return 'international';
  }

  static String resolvedRegion(String preference, {String? countryCode}) {
    if (preference == 'automatic') return automaticRegion(countryCode);
    return QuickFoodRegion.byId(preference).catalogRegion;
  }

  static List<QuickFood> ranked({
    required String regionPreference,
    String cuisinePreference = 'international',
    required String mealType,
    String? countryCode,
  }) {
    final deviceCountry = (countryCode ?? deviceCountryCode()).toUpperCase();
    // An explicit food preference wins over physical/device location. This is
    // the common expat case: a Pakistani user in Saudi Arabia who chooses
    // Pakistan should not keep seeing Gulf food above biryani and dal.
    final country = switch (regionPreference) {
      'automatic' => deviceCountry,
      'pakistan' => 'PK',
      'korean' => 'KR',
      _ => '',
    };
    final region = resolvedRegion(regionPreference, countryCode: deviceCountry);
    final cuisines =
        cuisinePreference
            .toLowerCase()
            .split(',')
            .map((value) => value.trim().replaceAll(' ', '_'))
            .toSet();
    final scored =
        foods.map((food) {
            var score = 0;
            if (food.countries.contains(country)) score += 50;
            if (food.regions.contains(region)) score += 35;
            if (food.regions.any(cuisines.contains)) score += 25;
            if (food.mealTypes.contains(mealType)) score += 12;
            if (food.regions.contains('international')) score += 5;
            return (food: food, score: score);
          }).toList()
          ..sort((a, b) {
            final byScore = b.score.compareTo(a.score);
            return byScore != 0 ? byScore : a.food.name.compareTo(b.food.name);
          });
    return scored.map((entry) => entry.food).toList(growable: false);
  }

  static QuickFood? byId(String id) {
    for (final food in foods) {
      if (food.nutritionId == id) return food;
    }
    return null;
  }
}
