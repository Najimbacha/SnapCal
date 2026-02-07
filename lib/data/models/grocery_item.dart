import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'grocery_item.g.dart';

@HiveType(typeId: 5) // Ensure unique typeId
class GroceryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String amount; // e.g., "200g", "1 bunch"

  @HiveField(3)
  final String category; // e.g., "Produce", "Dairy"

  @HiveField(4)
  bool isChecked;

  GroceryItem({
    String? id,
    required this.name,
    this.amount = '',
    this.category = 'Other',
    this.isChecked = false,
  }) : id = id ?? const Uuid().v4();

  GroceryItem copyWith({
    String? name,
    String? amount,
    String? category,
    bool? isChecked,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
