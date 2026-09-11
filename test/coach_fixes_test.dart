import 'package:flutter_test/flutter_test.dart';
import 'package:snapcal/providers/assistant_provider.dart';

void main() {
  group('a long conversation stays under the server limit', () {
    Map<String, String> turn(String type, int length) => {
      'type': type,
      'content': 'x' * length,
    };

    int promptLength(List<Map<String, String>> turns) =>
        2000 + turns.fold<int>(0, (sum, t) => sum + t['content']!.length);

    test('each past turn is clipped', () {
      final fitted = Assistant.fitHistory([
        turn('assistant', 5000),
      ], promptLength);
      expect(fitted.single['content']!.length, Assistant.maxTurnChars + 1);
      expect(fitted.single['content']!.endsWith('…'), isTrue);
    });

    test('the oldest turns go first until it fits', () {
      final history = [
        for (var i = 0; i < 6; i++) turn(i.isEven ? 'user' : 'assistant', 700),
      ];
      final fitted = Assistant.fitHistory(
        history,
        promptLength,
        maxChars: 2000 + 700 * 2,
      );
      expect(fitted, hasLength(2));
      expect(fitted.last['type'], 'assistant');
    });

    test('a short conversation is sent whole', () {
      final history = [turn('user', 20), turn('assistant', 80)];
      expect(Assistant.fitHistory(history, promptLength), history);
    });
  });
}
