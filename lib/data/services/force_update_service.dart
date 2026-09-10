import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/config_service.dart';
import '../../widgets/update_available_modal.dart';

class _Version implements Comparable<_Version> {
  final int major;
  final int minor;
  final int patch;

  const _Version(this.major, this.minor, this.patch);

  factory _Version.parse(String version) {
    final cleaned = version.split('+').first.trim();
    final parts = cleaned.split('.');
    return _Version(
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    );
  }

  @override
  int compareTo(_Version other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(_Version other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$patch';
}

/// Tells people on an old version that a new one is out, and takes them to
/// the store to get it.
///
/// Driven from Firebase Remote Config: set `latest_version` to the version
/// just released (for example "1.0.25") and everyone below it sees the prompt
/// on their next launch. `update_prompt_title` and `update_prompt_message`
/// replace the built-in wording, and `update_url` where the button goes --
/// needed on iOS, which has no built-in store page. Nothing called this
/// before, so setting `latest_version` did nothing.
class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._internal();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._internal();

  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.snapcal.snapcal';

  /// "Later" holds the prompt off for this long. It used to hide it for good
  /// for that version, so one tap meant never hearing about it again.
  static const Duration snoozeFor = Duration(days: 3);

  static const String _snoozedAtKey = 'update_prompt_snoozed_at';

  SharedPreferences? _prefs;
  String? _installedVersion;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final info = await PackageInfo.fromPlatform();
      _installedVersion = '${info.version}+${info.buildNumber}';
      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ ForceUpdateService: init failed: $e');
    }
  }

  /// Shows the update prompt when a newer version is out. Returns whether it
  /// was shown, so other launch-time prompts can stand down.
  Future<bool> checkAndPrompt(BuildContext context) async {
    if (!_initialized) await init();
    final installed = _installedVersion;
    if (!_initialized || installed == null) return false;

    final config = ConfigService();
    if (!isNewer(config.latestVersion, installed)) return false;
    if (isSnoozed(_prefs?.getInt(_snoozedAtKey), DateTime.now())) return false;
    // With no store to send them to -- iOS, until update_url is set -- say
    // nothing rather than offer a button that goes nowhere.
    if (storeUri(configured: config.updateUrl, isAndroid: _isAndroid) == null) {
      return false;
    }
    if (!context.mounted) return false;

    await UpdateAvailableModal.show(
      context,
      title: config.updatePromptTitle,
      message: config.updatePromptMessage,
      onUpdate: openStore,
      onDismiss: _snooze,
    );
    return true;
  }

  /// Opens SnapCal's store page. [url] is a link a notification carried; it
  /// is used only when it points at an app store.
  Future<bool> openStore({String? url}) async {
    final uri = storeUri(
      preferred: url,
      configured: ConfigService().updateUrl,
      isAndroid: _isAndroid,
    );
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ ForceUpdateService: failed to open store: $e');
      return false;
    }
  }

  void _snooze() {
    _prefs?.setInt(_snoozedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  static bool isNewer(String latest, String installed) {
    if (latest.trim().isEmpty) return false;
    return _Version.parse(latest) > _Version.parse(installed);
  }

  @visibleForTesting
  static bool isSnoozed(int? snoozedAtMs, DateTime now) {
    if (snoozedAtMs == null) return false;
    final snoozedAt = DateTime.fromMillisecondsSinceEpoch(snoozedAtMs);
    return now.difference(snoozedAt) < snoozeFor;
  }

  /// The store link to open, or null when there is none to use.
  ///
  /// Only app-store links are accepted, so a notification cannot send people
  /// anywhere else. The notification's own link wins, then Remote Config,
  /// then SnapCal's Google Play page on Android.
  @visibleForTesting
  static Uri? storeUri({
    String? preferred,
    String? configured,
    required bool isAndroid,
  }) {
    for (final candidate in [preferred, configured]) {
      final uri = _storeLink(candidate);
      if (uri != null) return uri;
    }
    return isAndroid ? Uri.parse(androidStoreUrl) : null;
  }

  static Uri? _storeLink(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme == 'market' || uri.scheme == 'itms-apps') return uri;
    if (uri.scheme == 'https' &&
        (uri.host == 'play.google.com' || uri.host == 'apps.apple.com')) {
      return uri;
    }
    return null;
  }
}
