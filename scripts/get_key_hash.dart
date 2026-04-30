// ignore_for_file: avoid_print
import 'dart:convert';

void main() {
  const hex = 'DB:21:22:A3:21:02:26:97:56:82:E9:64:BD:29:85:50:67:F4:6C:E2';
  final bytes = hex.split(':').map((s) => int.parse(s, radix: 16)).toList();
  final hash = base64.encode(bytes);
  print('Facebook Key Hash: $hash');
}
