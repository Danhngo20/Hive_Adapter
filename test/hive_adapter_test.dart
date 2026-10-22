import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:slot14_3b_hive_adapter/models/task.dart';
import 'package:slot14_3b_hive_adapter/services/hive_service.dart';

void main() {
  test('lưu thẳng Task bằng adapter; đóng/mở lại vẫn còn; sort, update, delete', () async {
    final dir = Directory.systemTemp.createTempSync('hive_adapter_test');
    addTearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });
    Hive.init(dir.path);
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>(HiveService.boxName);

    final s = HiveService();
    await s.addTask(Task(id: 'a', title: 'cũ', createdAt: 1));
    await s.addTask(Task(id: 'b', title: 'mới', createdAt: 2));

    // Giả lập tắt/mở app
    await Hive.box<Task>(HiveService.boxName).close();
    await Hive.openBox<Task>(HiveService.boxName);

    var list = s.loadTasks();
    expect(list.map((t) => t.id), ['b', 'a']); // mới nhất trước
    expect(list.first, isA<Task>()); // đọc ra đúng object Task, không phải Map

    final a = list.last..isDone = true..title = 'sửa';
    await s.updateTask(a);
    await s.deleteTask(list.first);
    list = s.loadTasks();
    expect(list.length, 1);
    expect([list.first.title, list.first.isDone], ['sửa', true]);

    await s.clearTasks();
    expect(s.loadTasks(), isEmpty);
  });
}
