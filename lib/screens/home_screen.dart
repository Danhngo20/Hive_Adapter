import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/hive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService service = HiveService();
  final TextEditingController addController = TextEditingController();

  List<Task> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    addController.dispose();
    super.dispose();
  }

  void _loadData() {
    // loadTasks() là sync (đọc local nhanh)
    final loaded = service.loadTasks();
    setState(() {
      tasks = loaded;
      isLoading = false;
    });
  }

  Future<void> _addTask() async {
    final title = addController.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await service.addTask(task);
    addController.clear();
    _loadData();
  }

  Future<void> _toggleDone(Task task) async {
    task.isDone = !task.isDone;
    await service.updateTask(task);
    _loadData();
  }

  Future<void> _deleteTask(Task task) async {
    // Gỡ khỏi list trước (Dismissible cần widget biến mất ngay), rồi xóa trong box.
    setState(() {
      tasks.removeWhere((t) => t.id == task.id);
    });
    await service.deleteTask(task);
  }

  Future<void> _editTaskDialog(Task task) async {
    final controller = TextEditingController(text: task.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_note),
        title: const Text('Sửa task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tiêu đề mới',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    final newTitle = result.trim();
    if (newTitle.isEmpty) return;

    task.title = newTitle;
    await service.updateTask(task);
    _loadData();
  }

  Future<void> _clearAllDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever),
        title: const Text('Xóa tất cả?'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ task không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      tasks.clear();
    });
    await service.clearTasks();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Task Manager (Hive Adapter)'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: tasks.isEmpty ? null : _clearAllDialog,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Xóa tất cả',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    _ProgressHeader(
                      done: tasks.where((t) => t.isDone).length,
                      total: tasks.length,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: addController,
                              decoration: InputDecoration(
                                labelText: 'Nhập task mới',
                                prefixIcon: const Icon(Icons.add_task),
                                filled: true,
                                fillColor: cs.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addTask(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _addTask,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(64, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Thêm'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: tasks.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Dismissible(
                                  key: ValueKey(task.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => _deleteTask(task),
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.only(right: 24),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: cs.errorContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(Icons.delete, color: cs.onErrorContainer),
                                  ),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    elevation: 0,
                                    color: task.isDone
                                        ? cs.surfaceContainerLow
                                        : cs.surfaceContainerHigh,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      leading: Checkbox(
                                        value: task.isDone,
                                        shape: const CircleBorder(),
                                        onChanged: (_) => _toggleDone(task),
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          decoration: task.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task.isDone ? cs.outline : null,
                                        ),
                                      ),
                                      onTap: () => _editTaskDialog(task),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Xóa',
                                        onPressed: () => _deleteTask(task),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  total == 0
                      ? 'Hôm nay chưa có việc gì'
                      : done == total
                          ? 'Tuyệt vời! Xong hết rồi 🎉'
                          : 'Còn ${total - done} việc cần làm',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.inventory_2_rounded, color: cs.onPrimary.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$done / $total đã hoàn thành · Hive + TypeAdapter',
            style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                color: cs.onPrimary,
                backgroundColor: cs.onPrimary.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rtl, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 12),
          const Text('Chưa có task nào.', style: TextStyle(fontSize: 16)),
          Text('Thêm task đầu tiên ở phía trên nhé!',
              style: TextStyle(color: cs.outline)),
        ],
      ),
    );
  }
}
