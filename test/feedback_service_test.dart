import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/data/services/feedback_service.dart';

void main() {
  test(
    'feedback opens an email to the developer with the details filled in',
    () {
      final uri = FeedbackService.emailUri(
        subject: 'SnapCal feedback',
        appVersion: '1.0.25 (43)',
        platform: 'android 14',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, FeedbackService.supportEmail);
      expect(uri.queryParameters['subject'], 'SnapCal feedback');
      expect(uri.queryParameters['body'], contains('SnapCal 1.0.25 (43)'));
      expect(uri.queryParameters['body'], contains('android 14'));
    },
  );

  // Uri's own query encoding writes spaces as "+", which mail apps show as-is.
  test('spaces are encoded as %20, not "+"', () {
    final uri = FeedbackService.emailUri(
      subject: 'SnapCal feedback',
      appVersion: '1.0.25',
      platform: 'android',
    );
    expect(uri.toString(), contains('subject=SnapCal%20feedback'));
    expect(uri.toString(), isNot(contains('+')));
  });
}
