import 'package:hive/hive.dart';

// File này được build_runner sinh thêm: task.g.dart (chứa TaskAdapter)
part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  final int createdAt;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });
}
