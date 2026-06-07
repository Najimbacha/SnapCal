import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/config_service.dart';
import '../../widgets/update_available_modal.dart';

enum UpdateStatus { upToDate, available }

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

  bool operator <(_Version other) => compareTo(other) < 0;
  bool operator >(_Version other) => compareTo(other) > 0;

  @override
  String toString() => '$major.$minor.$patch';
}

class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._internal();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._internal();

  static const String _skipVersionPrefix = 'force_update_skip_version_';

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

  Future<void> checkAndPrompt(BuildContext context) async {
    if (!_initialized) await init();
    if (!_initialized || _installedVersion == null) return;

    final status = _checkStatus();
    if (status == UpdateStatus.upToDate) return;

    final latestVersion = ConfigService().latestVersion;
    if (_isVersionSkipped(latestVersion)) return;
    if (!context.mounted) return;

    await _showUpdateModal(context);
  }

  UpdateStatus _checkStatus() {
    final config = ConfigService();
    final latest = config.latestVersion;
    if (latest.isEmpty) return UpdateStatus.upToDate;

    final installed = _Version.parse(_installedVersion!);
    final latestV = _Version.parse(latest);

    if (latestV > installed) return UpdateStatus.available;
    return UpdateStatus.upToDate;
  }

  Future<void> openPlayStore() async {
    final url = ConfigService().updateUrl;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ ForceUpdateService: failed to open store: $e');
    }
  }

  void skipVersion(String version) {
    final key = '$_skipVersionPrefix$version';
    _prefs?.setBool(key, true);
  }

  bool _isVersionSkipped(String version) {
    return _prefs?.getBool('$_skipVersionPrefix$version') ?? false;
  }

  Future<void> _showUpdateModal(BuildContext context) async {
    final config = ConfigService();
    final latestVersion = config.latestVersion;

    await UpdateAvailableModal.show(
      context,
      title: config.updatePromptTitle,
      message: config.updatePromptMessage,
      onUpdate: openPlayStore,
      onDismiss: () => skipVersion(latestVersion),
    );
  }
}
