import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/meal_repository.dart';
import '../data/repositories/water_repository.dart';
import '../data/repositories/assistant_repository.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
Future<SettingsRepository> settingsRepository(SettingsRepositoryRef ref) async {
  final repo = SettingsRepository();
  await repo.init();
  return repo;
}

@Riverpod(keepAlive: true)
Future<MealRepository> mealRepository(MealRepositoryRef ref) async {
  final repo = MealRepository();
  await repo.init();
  return repo;
}

@Riverpod(keepAlive: true)
Future<WaterRepository> waterRepository(WaterRepositoryRef ref) async {
  final repo = WaterRepository();
  await repo.init();
  return repo;
}

@Riverpod(keepAlive: true)
Future<AssistantRepository> assistantRepository(AssistantRepositoryRef ref) async {
  final repo = AssistantRepository();
  await repo.init();
  return repo;
}
