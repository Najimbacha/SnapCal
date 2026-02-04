import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String TEST_API_KEY = 'AIzaSyBOnxjnJxKVmBYmpY8hWTsLkWVKfMEw1-w';

Future<void> testModel(String modelName) async {
  final url =
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent';
  print("\n🧪 TESTING MODEL: $modelName");
  print("Target: $url");

  final base64Image =
      "/9j/4AAQSkZJRgABAQEAAAAAAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wAALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAgP/2gAIAQEAAD8A/wD/2Q==";

  final Map<String, dynamic> payload = {
    'contents': [
      {
        'parts': [
          {'text': "Identify this food."},
          {
            'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
          },
        ],
      },
    ],
  };

  try {
    final response = await http.post(
      Uri.parse('$url?key=$TEST_API_KEY'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print("STATUS: ${response.statusCode}");
    if (response.statusCode == 200) {
      print("✅ SUCCESS! This model works.");
    } else {
      print("❌ FAILED. Body: ${response.body}");
    }
  } catch (e) {
    print("💥 EXCEPTION: $e");
  }
}

void main() async {
  print("🔍 STARTING MULTI-MODEL DIAGNOSTIC...");
  await testModel('gemini-1.5-flash');
  await testModel('gemini-1.5-flash-001');
  await testModel('gemini-1.5-pro');
  await testModel('gemini-pro');
}
