import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/core/network/api_client.dart';

void main() {
  test('the wait after a failed App Check grows, and stops at a minute', () {
    expect(ApiClient.appCheckBackoffFor(0), Duration.zero);
    expect(ApiClient.appCheckBackoffFor(1), const Duration(seconds: 1));
    expect(ApiClient.appCheckBackoffFor(2), const Duration(seconds: 2));
    expect(ApiClient.appCheckBackoffFor(3), const Duration(seconds: 4));
    expect(ApiClient.appCheckBackoffFor(4), const Duration(seconds: 8));
    expect(ApiClient.appCheckBackoffFor(5), const Duration(seconds: 16));
    expect(ApiClient.appCheckBackoffFor(6), const Duration(seconds: 32));
    // Long past the point where trying harder helps.
    expect(ApiClient.appCheckBackoffFor(7), const Duration(seconds: 60));
    expect(ApiClient.appCheckBackoffFor(50), const Duration(seconds: 60));
  });
}
