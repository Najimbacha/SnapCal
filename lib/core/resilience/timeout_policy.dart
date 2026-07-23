class TimeoutPolicy {
  TimeoutPolicy._();

  static const startup = Duration(seconds: 35);
  static const auth = Duration(seconds: 12);
  static const socialAuth = Duration(seconds: 30);
  static const aiScan = Duration(seconds: 60);
  static const assistant = Duration(seconds: 18);
  static const barcode = Duration(seconds: 8);
  static const mealPlanner = Duration(seconds: 60);
  static const mealPlannerAction = Duration(seconds: 30);
  static const firestore = Duration(seconds: 8);
  static const upload = Duration(seconds: 45);
  static const revenueCat = Duration(seconds: 20);
  static const camera = Duration(seconds: 6);
  static const gallery = Duration(seconds: 20);
  static const localStorage = Duration(seconds: 10);
  static const remoteConfig = Duration(seconds: 10);
}
