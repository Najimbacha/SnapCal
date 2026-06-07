import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/theme/app_motion.dart';

class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool filled;
  final double weight;
  final double grade;
  final double opticalSize;
  final bool mirrored;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.filled = false,
    this.weight = 450,
    this.grade = 0,
    this.opticalSize = 24,
    this.mirrored = false,
  });

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final shouldMirror = mirrored && direction == TextDirection.rtl;

    Widget child = TweenAnimationBuilder<double>(
      duration: AppMotion.maybeZero(context, AppMotion.standard),
      curve: AppMotion.standardCurve,
      tween: Tween<double>(end: filled ? 1 : 0),
      builder: (context, fill, child) {
        return Icon(
          icon,
          size: size,
          color: color,
          fill: fill,
          weight: weight,
          grade: grade,
          opticalSize: opticalSize,
        );
      },
    );

    if (shouldMirror) {
      child = Transform.scale(scaleX: -1, child: child);
    }

    return child;
  }
}

class AppSymbols {
  AppSymbols._();

  static const home = Symbols.home;
  static const scan = Symbols.document_scanner;
  static const camera = Symbols.photo_camera;
  static const barcode = Symbols.barcode_scanner;
  static const log = Symbols.receipt_long;
  static const diary = Symbols.menu_book;
  static const progress = Symbols.monitoring;
  static const aiCoach = Symbols.neurology;
  static const ai = Symbols.auto_awesome;
  static const profile = Symbols.account_circle;
  static const settings = Symbols.settings;
  static const premium = Symbols.workspace_premium;
  static const calories = Symbols.local_fire_department;
  static const protein = Symbols.fitness_center;
  static const carbs = Symbols.grain;
  static const fat = Symbols.water_drop;
  static const steps = Symbols.directions_walk;
  static const water = Symbols.water_drop;
  static const notifications = Symbols.notifications;
  static const search = Symbols.search;
  static const lock = Symbols.lock;
  static const edit = Symbols.edit;
  static const delete = Symbols.delete;
  static const success = Symbols.check_circle;
  static const error = Symbols.error;
  static const info = Symbols.info;
  static const offline = Symbols.wifi_off;
  static const close = Symbols.close;
  static const back = Symbols.arrow_back;
  static const forward = Symbols.arrow_forward;
  static const chevronRight = Symbols.chevron_right;
  static const chevronLeft = Symbols.chevron_left;
  static const refresh = Symbols.refresh;
  static const flash = Symbols.flash_on;
  static const flashOff = Symbols.flash_off;
  static const add = Symbols.add;
  static const remove = Symbols.remove;
  static const plus = Symbols.add;
  static const minus = Symbols.remove;
  static const more = Symbols.more_horiz;
  static const upload = Symbols.cloud_upload;
  static const download = Symbols.download;
  static const share = Symbols.share;
  static const compare = Symbols.compare_arrows;
  static const dragHandle = Symbols.drag_handle;
  static const calendar = Symbols.calendar_month;
  static const target = Symbols.track_changes;
  static const meal = Symbols.restaurant;
  static const rice = Symbols.set_meal;
  static const chicken = Symbols.set_meal;
  static const salad = Symbols.eco;
  static const soup = Symbols.set_meal;
  static const bread = Symbols.bakery_dining;
  static const pizza = Symbols.local_pizza;
  static const fruit = Symbols.eco;
  static const drink = Symbols.local_cafe;
  static const dessert = Symbols.cake;
  static const fries = Symbols.set_meal;

  // Migration aliases for older icon call sites. Keep these centralized so
  // screens do not depend on third-party icon families directly.
  static const activity = Symbols.monitoring;
  static const alertCircle = Symbols.error;
  static const alertTriangle = Symbols.warning;
  static const apple = Symbols.nutrition;
  static const armchair = Symbols.chair;
  static const arrowLeft = Symbols.arrow_back;
  static const arrowRight = Symbols.arrow_forward;
  static const arrowUp = Symbols.arrow_upward;
  static const barChart3 = Symbols.monitoring;
  static const beef = Symbols.set_meal;
  static const bell = Symbols.notifications;
  static const cake = Symbols.cake;
  static const calendarCheck = Symbols.event_available;
  static const calendarClock = Symbols.calendar_month;
  static const calendarDays = Symbols.calendar_month;
  static const calendarRange = Symbols.date_range;
  static const cameraOff = Symbols.no_photography;
  static const check = Symbols.check;
  static const checkCircle2 = Symbols.check_circle;
  static const chefHat = Symbols.restaurant;
  static const chevronDown = Symbols.keyboard_arrow_down;
  static const chevronUp = Symbols.keyboard_arrow_up;
  static const circle = Symbols.radio_button_unchecked;
  static const clipboardList = Symbols.checklist;
  static const clock = Symbols.schedule;
  static const clock3 = Symbols.schedule;
  static const cloud = Symbols.cloud;
  static const cloudOff = Symbols.cloud_off;
  static const coffee = Symbols.local_cafe;
  static const croissant = Symbols.bakery_dining;
  static const crown = Symbols.crown;
  static const droplet = Symbols.water_drop;
  static const droplets = Symbols.water_drop;
  static const dumbbell = Symbols.fitness_center;
  static const egg = Symbols.egg;
  static const eye = Symbols.visibility;
  static const eyeOff = Symbols.visibility_off;
  static const fileBarChart = Symbols.monitoring;
  static const fileText = Symbols.description;
  static const fish = Symbols.set_meal;
  static const flag = Symbols.flag;
  static const flame = Symbols.local_fire_department;
  static const footprints = Symbols.directions_walk;
  static const gem = Symbols.workspace_premium;
  static const heartPulse = Symbols.monitor_heart;
  static const history = Symbols.history;
  static const image = Symbols.image;
  static const imageOff = Symbols.image_not_supported;
  static const languages = Symbols.translate;
  static const leaf = Symbols.eco;
  static const lightbulb = Symbols.lightbulb;
  static const link = Symbols.link;
  static const list = Symbols.list;
  static const listChecks = Symbols.checklist;
  static const logOut = Symbols.logout;
  static const mail = Symbols.mail;
  static const messageCircle = Symbols.chat_bubble;
  static const moon = Symbols.dark_mode;
  static const moreHorizontal = Symbols.more_horiz;
  static const moreVertical = Symbols.more_vert;
  static const refreshCw = Symbols.refresh;
  static const ruler = Symbols.straighten;
  static const scale = Symbols.scale;
  static const settings2 = Symbols.tune;
  static const share2 = Symbols.share;
  static const shield = Symbols.shield;
  static const shieldCheck = Symbols.verified_user;
  static const shoppingBag = Symbols.shopping_bag;
  static const slidersHorizontal = Symbols.tune;
  static const smartphone = Symbols.phone_iphone;
  static const sparkles = Symbols.auto_awesome;
  static const star = Symbols.star;
  static const sun = Symbols.light_mode;
  static const sunMoon = Symbols.routine;
  static const trash2 = Symbols.delete;
  static const trendingDown = Symbols.trending_down;
  static const trendingUp = Symbols.trending_up;
  static const trophy = Symbols.trophy;
  static const user = Symbols.person;
  static const userCircle = Symbols.account_circle;
  static const userCircle2 = Symbols.account_circle;
  static const userPlus = Symbols.person_add;
  static const utensils = Symbols.restaurant;
  static const utensilsCrossed = Symbols.restaurant;
  static const video = Symbols.videocam;
  static const wallet = Symbols.wallet;
  static const wand2 = Symbols.auto_awesome;
  static const wheat = Symbols.grain;
  static const wifiOff = Symbols.wifi_off;
  static const x = Symbols.close;
  static const zap = Symbols.bolt;
}
