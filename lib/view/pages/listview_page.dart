import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:junior_app/services/localization_extension.dart';
import '../../view_model/todo_view_model.dart';
import 'todo_detail.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<TodoViewModel>().fetchTodos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodoViewModel>();

    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndexFromFilter(vm.filter),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('home')),
          backgroundColor: Colors.blue.shade800,
          bottom: TabBar(
            onTap: (i) => vm.setFilter(_filterFromTabIndex(i)),
            tabs: [
              Tab(text: '${context.tr('all')} (${vm.countAll})'),
              Tab(text: '${context.tr('completed')} (${vm.countCompleted})'),
              Tab(text: '${context.tr('uncompleted')} (${vm.countUncompleted})'),
            ],
          ),
        ),
        body: Builder(
          builder: (_) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.error != null) {
              return Center(
                child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
              );
            }

            return TabBarView(
              // Keep pages alive so switching tabs is snappy
              physics: const BouncingScrollPhysics(),
              children: [
                _AllTodosList(list: vm.allTodos),
                _CompletedTodosList(list: vm.completedTodos),
                _UncompletedTodosList(list: vm.uncompletedTodos),
              ],
            );
          },
        ),
      ),
    );
  }

  int _tabIndexFromFilter(TodoFilter f) {
    switch (f) {
      case TodoFilter.completed:
        return 1;
      case TodoFilter.uncompleted:
        return 2;
      case TodoFilter.all:
      default:
        return 0;
    }
  }

  TodoFilter _filterFromTabIndex(int i) {
    switch (i) {
      case 1:
        return TodoFilter.completed;
      case 2:
        return TodoFilter.uncompleted;
      case 0:
      default:
        return TodoFilter.all;
    }
  }
}

/// ---------- All (neutral design) ----------
class _AllTodosList extends StatelessWidget {
  const _AllTodosList({required this.list});
  final List<dynamic> list;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();
    if (list.isEmpty) {
      return const _EmptyState(label: 'No todos found');
    }
    return RefreshIndicator(
      onRefresh: vm.fetchTodos,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, i) {
          final todo = list[i];
          return _AllTodoTile(
            title: todo.title,
            completed: todo.completed == true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TodoDetailPage(todo: todo)),
            ),
          );
        },
      ),
    );
  }
}

class _AllTodoTile extends StatelessWidget {
  const _AllTodoTile({
    required this.title,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
              color: Colors.black.withOpacity(0.06),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.circle_outlined,
              color: completed ? Colors.green : cs.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  decoration:
                      completed ? TextDecoration.lineThrough : TextDecoration.none,
                  color: completed ? cs.onSurface.withOpacity(0.6) : cs.onSurface,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// ---------- Completed (success card design) ----------
class _CompletedTodosList extends StatelessWidget {
  const _CompletedTodosList({required this.list});
  final List<dynamic> list;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();
    if (list.isEmpty) {
      return const _EmptyState(label: 'No completed todos');
    }
    return RefreshIndicator(
      onRefresh: vm.fetchTodos,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final todo = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CompletedCard(
              title: todo.title,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodoDetailPage(todo: todo)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade500, Colors.green.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// ---------- Uncompleted (warning/dotted border design) ----------
class _UncompletedTodosList extends StatelessWidget {
  const _UncompletedTodosList({required this.list});
  final List<dynamic> list;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TodoViewModel>();
    if (list.isEmpty) {
      return const _EmptyState(label: 'No uncompleted todos');
    }
    return RefreshIndicator(
      onRefresh: vm.fetchTodos,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final todo = list[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UncompletedCard(
              title: todo.title,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TodoDetailPage(todo: todo)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UncompletedCard extends StatelessWidget {
  const _UncompletedCard({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.shade700,
            style: BorderStyle.solid, // Flutter doesn’t support dashed out-of-box in BoxDecoration
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'To do',
                style: TextStyle(color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Shared ----------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: cs.outline),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: cs.outline)),
        ],
      ),
    );
  }
}
