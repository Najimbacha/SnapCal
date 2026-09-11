import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';

/// "Send feedback" in Settings: an email to the developer, with the app
/// version and platform filled in so a report can be acted on.
///
/// It is its own option in Settings and never a question put before the review
/// prompt. Asking "do you like SnapCal?" first and showing the rating only to
/// people who say yes is review gating, which Google Play forbids.
class FeedbackService {
  FeedbackService._();

  static const String supportEmail = 'najimbacha1@gmail.com';

  @visibleForTesting
  static Uri emailUri({
    required String subject,
    required String appVersion,
    required String platform,
  }) {
    final body = '\n\n\n---\nSnapCal $appVersion · $platform';
    // Encoded by hand: Uri's queryParameters writes spaces as "+", which
    // several mail apps then show literally.
    return Uri.parse(
      'mailto:$supportEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
  }

  static Future<void> send(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    var version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}

    final uri = emailUri(
      subject: l10n.feedback_email_subject,
      appVersion: version,
      platform:
          '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (opened) return;

    // No mail app on the phone: hand them the address instead.
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.feedback_email_copied(supportEmail))),
    );
  }
}
