import 'package:flutter/widgets.dart';

/// Wazn's own icon set, drawn for the app on a 24px grid with 2px round
/// strokes, and bundled as the WaznIcons font (assets/fonts/WaznIcons.ttf).
///
/// Every icon in the app comes from here. Use these like any IconData:
/// `Icon(WaznIcons.water)`. Icons that point along the reading direction
/// (back, forward, the side chevrons, log out) flip on their own in Arabic,
/// so never swap or mirror them by hand.
abstract final class WaznIcons {
  static const _family = 'WaznIcons';

  /// Home tab.
  static const IconData home = IconData(0xe000, fontFamily: _family);

  /// Home tab, selected.
  static const IconData homeFilled = IconData(0xe001, fontFamily: _family);

  /// Food Log tab.
  static const IconData log = IconData(0xe002, fontFamily: _family);

  /// Food Log tab, selected.
  static const IconData logFilled = IconData(0xe003, fontFamily: _family);

  /// Stats tab and reports.
  static const IconData stats = IconData(0xe004, fontFamily: _family);

  /// Stats tab, selected.
  static const IconData statsFilled = IconData(0xe005, fontFamily: _family);

  /// Profile tab and account.
  static const IconData profile = IconData(0xe006, fontFamily: _family);

  /// Profile tab, selected.
  static const IconData profileFilled = IconData(0xe007, fontFamily: _family);

  /// Scan a meal with the camera.
  static const IconData scan = IconData(0xe008, fontFamily: _family);

  /// Take or pick a photo.
  static const IconData camera = IconData(0xe009, fontFamily: _family);

  /// Scan a barcode.
  static const IconData barcode = IconData(0xe00a, fontFamily: _family);

  /// Log a meal by voice.
  static const IconData voice = IconData(0xe00b, fontFamily: _family);

  /// Search foods.
  static const IconData search = IconData(0xe00c, fontFamily: _family);

  /// A meal or food entry.
  static const IconData meal = IconData(0xe00d, fontFamily: _family);

  /// Breakfast.
  static const IconData breakfast = IconData(0xe00e, fontFamily: _family);

  /// Lunch.
  static const IconData lunch = IconData(0xe00f, fontFamily: _family);

  /// Dinner.
  static const IconData dinner = IconData(0xe010, fontFamily: _family);

  /// Snack.
  static const IconData snack = IconData(0xe011, fontFamily: _family);

  /// Calories.
  static const IconData calories = IconData(0xe012, fontFamily: _family);

  /// Protein.
  static const IconData protein = IconData(0xe013, fontFamily: _family);

  /// Carbohydrates.
  static const IconData carbs = IconData(0xe014, fontFamily: _family);

  /// Fat.
  static const IconData fat = IconData(0xe015, fontFamily: _family);

  /// Water and hydration.
  static const IconData water = IconData(0xe016, fontFamily: _family);

  /// Steps.
  static const IconData steps = IconData(0xe017, fontFamily: _family);

  /// Body weight.
  static const IconData weight = IconData(0xe018, fontFamily: _family);

  /// Exercise and workouts.
  static const IconData exercise = IconData(0xe019, fontFamily: _family);

  /// A goal or target.
  static const IconData goal = IconData(0xe01a, fontFamily: _family);

  /// Progress trend.
  static const IconData trend = IconData(0xe01b, fontFamily: _family);

  /// Streaks and achievements.
  static const IconData streak = IconData(0xe01c, fontFamily: _family);

  /// AI features.
  static const IconData ai = IconData(0xe01d, fontFamily: _family);

  /// The AI nutrition coach.
  static const IconData coach = IconData(0xe01e, fontFamily: _family);

  /// Wazn Pro.
  static const IconData pro = IconData(0xe01f, fontFamily: _family);

  /// Dates and history.
  static const IconData calendar = IconData(0xe020, fontFamily: _family);

  /// Grocery list.
  static const IconData grocery = IconData(0xe021, fontFamily: _family);

  /// Notifications and reminders.
  static const IconData notifications = IconData(0xe022, fontFamily: _family);

  /// Settings and preferences.
  static const IconData settings = IconData(0xe023, fontFamily: _family);

  /// A favorite, not yet chosen.
  static const IconData star = IconData(0xe024, fontFamily: _family);

  /// A chosen favorite.
  static const IconData starFilled = IconData(0xe025, fontFamily: _family);

  /// Close.
  static const IconData close = IconData(0xe026, fontFamily: _family);

  /// Refresh.
  static const IconData refresh = IconData(0xe027, fontFamily: _family);

  /// Rotate ccw.
  static const IconData rotateCcw = IconData(0xe028, fontFamily: _family);

  /// Chevron right.
  static const IconData chevronRight = IconData(
    0xe029,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Chevron left.
  static const IconData chevronLeft = IconData(
    0xe02a,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Chevron down.
  static const IconData chevronDown = IconData(0xe02b, fontFamily: _family);

  /// Chevron up.
  static const IconData chevronUp = IconData(0xe02c, fontFamily: _family);

  /// Plus.
  static const IconData plus = IconData(0xe02d, fontFamily: _family);

  /// Minus.
  static const IconData minus = IconData(0xe02e, fontFamily: _family);

  /// Plus circle.
  static const IconData plusCircle = IconData(0xe02f, fontFamily: _family);

  /// Check.
  static const IconData check = IconData(0xe030, fontFamily: _family);

  /// Success.
  static const IconData success = IconData(0xe031, fontFamily: _family);

  /// Error.
  static const IconData error = IconData(0xe032, fontFamily: _family);

  /// Warning.
  static const IconData warning = IconData(0xe033, fontFamily: _family);

  /// Info.
  static const IconData info = IconData(0xe034, fontFamily: _family);

  /// Blocked.
  static const IconData blocked = IconData(0xe035, fontFamily: _family);

  /// Delete.
  static const IconData delete = IconData(0xe036, fontFamily: _family);

  /// Edit.
  static const IconData edit = IconData(0xe037, fontFamily: _family);

  /// Eraser.
  static const IconData eraser = IconData(0xe038, fontFamily: _family);

  /// Back.
  static const IconData back = IconData(
    0xe039,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Forward.
  static const IconData forward = IconData(
    0xe03a,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Arrow up.
  static const IconData arrowUp = IconData(0xe03b, fontFamily: _family);

  /// Arrow up right.
  static const IconData arrowUpRight = IconData(0xe03c, fontFamily: _family);

  /// Arrow down right.
  static const IconData arrowDownRight = IconData(0xe03d, fontFamily: _family);

  /// Compare.
  static const IconData compare = IconData(0xe03e, fontFamily: _family);

  /// Repeat.
  static const IconData repeat = IconData(0xe03f, fontFamily: _family);

  /// Shuffle.
  static const IconData shuffle = IconData(0xe040, fontFamily: _family);

  /// More.
  static const IconData more = IconData(0xe041, fontFamily: _family);

  /// More vertical.
  static const IconData moreVertical = IconData(0xe042, fontFamily: _family);

  /// Grip.
  static const IconData grip = IconData(0xe043, fontFamily: _family);

  /// Share.
  static const IconData share = IconData(0xe044, fontFamily: _family);

  /// Download.
  static const IconData download = IconData(0xe045, fontFamily: _family);

  /// Upload.
  static const IconData upload = IconData(0xe046, fontFamily: _family);

  /// Link.
  static const IconData link = IconData(0xe047, fontFamily: _family);

  /// Log out.
  static const IconData logOut = IconData(
    0xe048,
    fontFamily: _family,
    matchTextDirection: true,
  );

  /// Loader.
  static const IconData loader = IconData(0xe049, fontFamily: _family);

  /// Lock.
  static const IconData lock = IconData(0xe04a, fontFamily: _family);

  /// Key.
  static const IconData key = IconData(0xe04b, fontFamily: _family);

  /// Shield.
  static const IconData shield = IconData(0xe04c, fontFamily: _family);

  /// Shield check.
  static const IconData shieldCheck = IconData(0xe04d, fontFamily: _family);

  /// Eye.
  static const IconData eye = IconData(0xe04e, fontFamily: _family);

  /// Eye off.
  static const IconData eyeOff = IconData(0xe04f, fontFamily: _family);

  /// Offline.
  static const IconData offline = IconData(0xe050, fontFamily: _family);

  /// Cloud.
  static const IconData cloud = IconData(0xe051, fontFamily: _family);

  /// Cloud off.
  static const IconData cloudOff = IconData(0xe052, fontFamily: _family);

  /// Flash.
  static const IconData flash = IconData(0xe053, fontFamily: _family);

  /// Flash off.
  static const IconData flashOff = IconData(0xe054, fontFamily: _family);

  /// Camera off.
  static const IconData cameraOff = IconData(0xe055, fontFamily: _family);

  /// Notifications off.
  static const IconData notificationsOff = IconData(
    0xe056,
    fontFamily: _family,
  );

  /// Image.
  static const IconData image = IconData(0xe057, fontFamily: _family);

  /// Image off.
  static const IconData imageOff = IconData(0xe058, fontFamily: _family);

  /// Clock.
  static const IconData clock = IconData(0xe059, fontFamily: _family);

  /// Timer.
  static const IconData timer = IconData(0xe05a, fontFamily: _family);

  /// Hourglass.
  static const IconData hourglass = IconData(0xe05b, fontFamily: _family);

  /// History.
  static const IconData history = IconData(0xe05c, fontFamily: _family);

  /// Calendar check.
  static const IconData calendarCheck = IconData(0xe05d, fontFamily: _family);

  /// Activity.
  static const IconData activity = IconData(0xe05e, fontFamily: _family);

  /// Heart pulse.
  static const IconData heartPulse = IconData(0xe05f, fontFamily: _family);

  /// Trend down.
  static const IconData trendDown = IconData(0xe060, fontFamily: _family);

  /// Theme.
  static const IconData theme = IconData(0xe061, fontFamily: _family);

  /// Circle.
  static const IconData circle = IconData(0xe062, fontFamily: _family);

  /// Circle dot.
  static const IconData circleDot = IconData(0xe063, fontFamily: _family);

  /// Square.
  static const IconData square = IconData(0xe064, fontFamily: _family);

  /// Mail.
  static const IconData mail = IconData(0xe065, fontFamily: _family);

  /// Chat.
  static const IconData chat = IconData(0xe066, fontFamily: _family);

  /// Smartphone.
  static const IconData smartphone = IconData(0xe067, fontFamily: _family);

  /// Watch.
  static const IconData watch = IconData(0xe068, fontFamily: _family);

  /// Video.
  static const IconData video = IconData(0xe069, fontFamily: _family);

  /// File text.
  static const IconData fileText = IconData(0xe06a, fontFamily: _family);

  /// List.
  static const IconData list = IconData(0xe06b, fontFamily: _family);

  /// List checks.
  static const IconData listChecks = IconData(0xe06c, fontFamily: _family);

  /// Inbox.
  static const IconData inbox = IconData(0xe06d, fontFamily: _family);

  /// Layers.
  static const IconData layers = IconData(0xe06e, fontFamily: _family);

  /// Bookmark plus.
  static const IconData bookmarkPlus = IconData(0xe06f, fontFamily: _family);

  /// Tag.
  static const IconData tag = IconData(0xe070, fontFamily: _family);

  /// Hash.
  static const IconData hash = IconData(0xe071, fontFamily: _family);

  /// Lightbulb.
  static const IconData lightbulb = IconData(0xe072, fontFamily: _family);

  /// Languages.
  static const IconData languages = IconData(0xe073, fontFamily: _family);

  /// Globe.
  static const IconData globe = IconData(0xe074, fontFamily: _family);

  /// Map pin.
  static const IconData mapPin = IconData(0xe075, fontFamily: _family);

  /// Locate.
  static const IconData locate = IconData(0xe076, fontFamily: _family);

  /// Flag.
  static const IconData flag = IconData(0xe077, fontFamily: _family);

  /// Facebook.
  static const IconData facebook = IconData(0xe078, fontFamily: _family);

  /// Terminal.
  static const IconData terminal = IconData(0xe079, fontFamily: _family);

  /// Bug.
  static const IconData bug = IconData(0xe07a, fontFamily: _family);

  /// Hard drive.
  static const IconData hardDrive = IconData(0xe07b, fontFamily: _family);

  /// Package.
  static const IconData package = IconData(0xe07c, fontFamily: _family);

  /// Combine.
  static const IconData combine = IconData(0xe07d, fontFamily: _family);

  /// Wallet.
  static const IconData wallet = IconData(0xe07e, fontFamily: _family);

  /// Coins.
  static const IconData coins = IconData(0xe07f, fontFamily: _family);

  /// Piggy bank.
  static const IconData piggyBank = IconData(0xe080, fontFamily: _family);

  /// Shopping cart.
  static const IconData shoppingCart = IconData(0xe081, fontFamily: _family);

  /// Soup.
  static const IconData soup = IconData(0xe082, fontFamily: _family);

  /// Salad.
  static const IconData salad = IconData(0xe083, fontFamily: _family);

  /// Croissant.
  static const IconData croissant = IconData(0xe084, fontFamily: _family);

  /// Coffee.
  static const IconData coffee = IconData(0xe085, fontFamily: _family);

  /// Egg.
  static const IconData egg = IconData(0xe086, fontFamily: _family);

  /// Fish.
  static const IconData fish = IconData(0xe087, fontFamily: _family);

  /// Pizza.
  static const IconData pizza = IconData(0xe088, fontFamily: _family);

  /// Sandwich.
  static const IconData sandwich = IconData(0xe089, fontFamily: _family);

  /// Cake.
  static const IconData cake = IconData(0xe08a, fontFamily: _family);

  /// Chef hat.
  static const IconData chefHat = IconData(0xe08b, fontFamily: _family);

  /// Leaf.
  static const IconData leaf = IconData(0xe08c, fontFamily: _family);

  /// Sprout.
  static const IconData sprout = IconData(0xe08d, fontFamily: _family);

  /// Refrigerator.
  static const IconData refrigerator = IconData(0xe08e, fontFamily: _family);

  /// Armchair.
  static const IconData armchair = IconData(0xe08f, fontFamily: _family);

  /// User plus.
  static const IconData userPlus = IconData(0xe090, fontFamily: _family);

  /// Person standing.
  static const IconData personStanding = IconData(0xe091, fontFamily: _family);

  /// Ruler.
  static const IconData ruler = IconData(0xe092, fontFamily: _family);
}
