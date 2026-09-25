import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';
import 'wazn_icons.dart';

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

  static const home = WaznIcons.home;
  static const scan = WaznIcons.scan;
  static const camera = WaznIcons.camera;
  static const barcode = WaznIcons.barcode;
  static const log = WaznIcons.log;
  static const diary = WaznIcons.log;
  static const progress = WaznIcons.stats;
  static const aiCoach = WaznIcons.coach;
  static const ai = WaznIcons.ai;
  static const profile = WaznIcons.profile;
  static const settings = WaznIcons.settings;
  static const premium = WaznIcons.pro;
  static const calories = WaznIcons.calories;
  static const protein = WaznIcons.protein;
  static const carbs = WaznIcons.carbs;
  static const fat = WaznIcons.fat;
  static const steps = WaznIcons.steps;
  static const water = WaznIcons.water;
  static const notifications = WaznIcons.notifications;
  static const search = WaznIcons.search;
  static const lock = WaznIcons.lock;
  static const edit = WaznIcons.edit;
  static const delete = WaznIcons.delete;
  static const success = WaznIcons.success;
  static const error = WaznIcons.error;
  static const info = WaznIcons.info;
  static const offline = WaznIcons.offline;
  static const close = WaznIcons.close;
  static const back = WaznIcons.back;
  static const forward = WaznIcons.forward;
  static const chevronRight = WaznIcons.chevronRight;
  static const chevronLeft = WaznIcons.chevronLeft;
  static const refresh = WaznIcons.refresh;
  static const flash = WaznIcons.flash;
  static const flashOff = WaznIcons.flashOff;
  static const add = WaznIcons.plus;
  static const remove = WaznIcons.minus;
  static const plus = WaznIcons.plus;
  static const minus = WaznIcons.minus;
  static const more = WaznIcons.more;
  static const upload = WaznIcons.upload;
  static const download = WaznIcons.download;
  static const share = WaznIcons.share;
  static const compare = WaznIcons.compare;
  static const dragHandle = WaznIcons.grip;
  static const calendar = WaznIcons.calendar;
  static const target = WaznIcons.goal;
  static const meal = WaznIcons.meal;
  static const rice = WaznIcons.soup;
  static const chicken = WaznIcons.protein;
  static const salad = WaznIcons.salad;
  static const soup = WaznIcons.soup;
  static const bread = WaznIcons.croissant;
  static const pizza = WaznIcons.pizza;
  static const fruit = WaznIcons.snack;
  static const drink = WaznIcons.coffee;
  static const dessert = WaznIcons.cake;
  static const fries = WaznIcons.sandwich;

  // Migration aliases for older icon call sites. Keep these centralized so
  // screens do not depend on third-party icon families directly.
  static const activity = WaznIcons.activity;
  static const alertCircle = WaznIcons.error;
  static const alertTriangle = WaznIcons.warning;
  static const apple = WaznIcons.snack;
  static const armchair = WaznIcons.armchair;
  static const arrowLeft = WaznIcons.back;
  static const arrowRight = WaznIcons.forward;
  static const arrowUp = WaznIcons.arrowUp;
  static const barChart3 = WaznIcons.stats;
  static const beef = WaznIcons.protein;
  static const bell = WaznIcons.notifications;
  static const cake = WaznIcons.cake;
  static const calendarCheck = WaznIcons.calendarCheck;
  static const calendarClock = WaznIcons.calendar;
  static const calendarDays = WaznIcons.calendar;
  static const calendarRange = WaznIcons.calendar;
  static const cameraOff = WaznIcons.cameraOff;
  static const check = WaznIcons.check;
  static const checkCircle2 = WaznIcons.success;
  static const chefHat = WaznIcons.meal;
  static const chevronDown = WaznIcons.chevronDown;
  static const chevronUp = WaznIcons.chevronUp;
  static const circle = WaznIcons.circle;
  static const clipboardList = WaznIcons.log;
  static const clock = WaznIcons.clock;
  static const clock3 = WaznIcons.clock;
  static const cloud = WaznIcons.cloud;
  static const cloudOff = WaznIcons.cloudOff;
  static const coffee = WaznIcons.coffee;
  static const croissant = WaznIcons.croissant;
  static const crown = WaznIcons.pro;
  static const droplet = WaznIcons.water;
  static const droplets = WaznIcons.water;
  static const dumbbell = WaznIcons.exercise;
  static const egg = WaznIcons.egg;
  static const eye = WaznIcons.eye;
  static const eyeOff = WaznIcons.eyeOff;
  static const fileBarChart = WaznIcons.stats;
  static const fileText = WaznIcons.fileText;
  static const fish = WaznIcons.fish;
  static const flag = WaznIcons.flag;
  static const flame = WaznIcons.calories;
  static const footprints = WaznIcons.steps;
  static const gem = WaznIcons.pro;
  static const heartPulse = WaznIcons.heartPulse;
  static const history = WaznIcons.history;
  static const image = WaznIcons.image;
  static const imageOff = WaznIcons.imageOff;
  static const languages = WaznIcons.languages;
  static const leaf = WaznIcons.leaf;
  static const lightbulb = WaznIcons.lightbulb;
  static const link = WaznIcons.link;
  static const list = WaznIcons.list;
  static const listChecks = WaznIcons.listChecks;
  static const logOut = WaznIcons.logOut;
  static const mail = WaznIcons.mail;
  static const messageCircle = WaznIcons.chat;
  static const moon = WaznIcons.dinner;
  static const moreHorizontal = WaznIcons.more;
  static const moreVertical = WaznIcons.moreVertical;
  static const refreshCw = WaznIcons.refresh;
  static const ruler = WaznIcons.ruler;
  static const scale = WaznIcons.weight;
  static const settings2 = WaznIcons.settings;
  static const share2 = WaznIcons.share;
  static const shield = WaznIcons.shield;
  static const shieldCheck = WaznIcons.shieldCheck;
  static const shoppingBag = WaznIcons.grocery;
  static const slidersHorizontal = WaznIcons.settings;
  static const smartphone = WaznIcons.smartphone;
  static const sparkles = WaznIcons.ai;
  static const star = WaznIcons.star;
  static const sun = WaznIcons.lunch;
  static const sunMoon = WaznIcons.theme;
  static const trash2 = WaznIcons.delete;
  static const trendingDown = WaznIcons.trendDown;
  static const trendingUp = WaznIcons.trend;
  static const trophy = WaznIcons.streak;
  static const user = WaznIcons.profile;
  static const userCircle = WaznIcons.profile;
  static const userCircle2 = WaznIcons.profile;
  static const userPlus = WaznIcons.userPlus;
  static const utensils = WaznIcons.meal;
  static const utensilsCrossed = WaznIcons.meal;
  static const video = WaznIcons.video;
  static const wallet = WaznIcons.wallet;
  static const male = WaznIcons.profile;
  static const female = WaznIcons.profile;
  static const run = WaznIcons.personStanding;
  static const balance = WaznIcons.weight;
  static const wand2 = WaznIcons.ai;
  static const wheat = WaznIcons.carbs;
  static const wifiOff = WaznIcons.offline;
  static const x = WaznIcons.close;
  static const zap = WaznIcons.flash;
}
