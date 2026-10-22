import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class HiveService {
  static const String boxName = 'taskBox';

  // Box<Task>: lưu thẳng object Task, KHÔNG cần toMap/fromMap.
  Box<Task> get _box => Hive.box<Task>(boxName);

  /// Mỗi task là 1 entry riêng, key = task.id (giống 1 dòng trong bảng).
  /// Sắp xếp mới nhất lên đầu.
  List<Task> loadTasks() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addTask(Task task) => _box.put(task.id, task);

  /// Task extends HiveObject nên tự biết mình nằm ở key nào: chỉ cần save().
  Future<void> updateTask(Task task) => task.save();

  Future<void> deleteTask(Task task) => task.delete();

  Future<void> clearTasks() => _box.clear();
}
