import 'package:flutter/material.dart';

import '../domain/coordinate.dart';
import '../domain/task_result.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, required this.results});
  final List<TaskResult> results;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Результати')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final result = results[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.route)),
                title: Text(result.pathDescription),
                subtitle: Text('Завдання ${result.task.id}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ResultDetailPage(result: result),
                )),
              ),
            );
          },
        ),
      );
}

class ResultDetailPage extends StatelessWidget {
  const ResultDetailPage({super.key, required this.result});
  final TaskResult result;

  @override
  Widget build(BuildContext context) {
    final task = result.task;
    final pathSet = result.path.toSet();
    return Scaffold(
      appBar: AppBar(title: Text('Завдання ${task.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                result.pathDescription,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(builder: (context, constraints) {
                final minimumWidth = task.width * 40.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < minimumWidth
                        ? minimumWidth
                        : constraints.maxWidth,
                    child: Column(
                      children: [
                        for (var y = 0; y < task.field.length; y++)
                          Row(
                            children: [
                              for (var x = 0; x < task.field[y].length; x++)
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: _GridCell(
                                      coordinate: Coordinate(x: x, y: y),
                                      blocked:
                                          task.field[y][x].toUpperCase() == 'X',
                                      isStart:
                                          task.start == Coordinate(x: x, y: y),
                                      isEnd: task.end == Coordinate(x: x, y: y),
                                      isPath: pathSet
                                          .contains(Coordinate(x: x, y: y)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _Legend(color: Color(0xFF64FFDA), label: 'Початок'),
              _Legend(color: Color(0xFF009688), label: 'Кінець'),
              _Legend(color: Colors.black, label: 'Перешкода'),
              _Legend(color: Color(0xFF4CAF50), label: 'Шлях'),
              _Legend(
                  color: Colors.white, border: true, label: 'Вільна комірка'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.coordinate,
    required this.blocked,
    required this.isStart,
    required this.isEnd,
    required this.isPath,
  });

  final Coordinate coordinate;
  final bool blocked;
  final bool isStart;
  final bool isEnd;
  final bool isPath;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (blocked) {
      color = Colors.black;
    } else if (isStart) {
      color = const Color(0xFF64FFDA);
    } else if (isEnd) {
      color = const Color(0xFF009688);
    } else if (isPath) {
      color = const Color(0xFF4CAF50);
    } else {
      color = Colors.white;
    }

    final dark = blocked || isEnd;
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFFBDBDBD), width: 0.6),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            '${coordinate.x}.${coordinate.y}',
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.white : Colors.black87,
              fontWeight:
                  isStart || isEnd ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, this.border = false});
  final Color color;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: border ? const Color(0xFFBDBDBD) : color,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      );
}
