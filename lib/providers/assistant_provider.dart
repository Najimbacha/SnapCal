import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/assistant_repository.dart';
import '../data/services/gemini_service.dart';
import 'repository_providers.dart';

part 'assistant_provider.g.dart';

@Riverpod(keepAlive: true)
class Assistant extends _$Assistant {
  AssistantRepository? _repo;
  final AIService _aiService = AIService();

  @override
  FutureOr<void> build() {}

  Future<String> fetchRecommendations(String query, {int? currentCalories}) async {
    _repo ??= await ref.read(assistantRepositoryProvider.future);
    if (currentCalories != null) {
      await _repo!.saveCalorieSnapshot(currentCalories);
    }
    final result = await _aiService.generateText(query);
    return result;
  }

  Future<String> analyzeImage(String base64Image, String prompt) async {
    final bytes = Uri.tryParse(base64Image)?.data?.contentAsBytes();
    if (bytes == null) return 'Error: Invalid image data';
    final result = await _aiService.analyzeFood(bytes);
    return result.toString();
  }
}
