import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/task_api.dart';
import '../domain/coordinate.dart';
import '../domain/path_task.dart';
import '../domain/shortest_path_solver.dart';
import '../domain/task_result.dart';
import 'result_pages.dart';

List<Coordinate> _solveTask(PathTask task) =>
    const ShortestPathSolver().solve(task);

class ProcessPage extends StatefulWidget {
  const ProcessPage({super.key, required this.api});
  final TaskApi api;

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  bool _loading = true;
  bool _fetching = true;
  bool _sending = false;
  double _progress = 0;
  String? _error;
  List<TaskResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _fetching = true;
      _progress = 0;
      _error = null;
      _results = const [];
    });
    try {
      final tasks = await widget.api.fetchTasks();
      if (!mounted) return;
      setState(() => _fetching = false);
      final results = <TaskResult>[];
      for (final task in tasks) {
        // Run the calculation outside the UI isolate to keep frames responsive.
        final path = await compute(_solveTask, task);
        if (!mounted) return;
        if (path.isEmpty) {
          throw TaskApiException('Для завдання ${task.id} шлях не знайдено.');
        }
        results.add(TaskResult(task: task, path: path));
        setState(() => _progress = results.length / tasks.length);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }
      setState(() => _results = List.unmodifiable(results));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendResults() async {
    if (_sending || _loading || _results.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.api.submitResults(_results);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ResultsPage(results: _results),
      ));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = !_loading && _results.isNotEmpty;
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Обчислення')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const SizedBox(height: 64),
                          Text(
                            _fetching && _loading
                                ? 'Завантаження завдань…'
                                : completed
                                    ? 'Розрахунки завершено'
                                    : _loading
                                        ? 'Обчислення найкоротших шляхів…'
                                        : 'Не вдалося виконати розрахунки',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: SizedBox.square(
                              dimension: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox.expand(
                                    child: CircularProgressIndicator(
                                      value: _fetching && _loading
                                          ? null
                                          : _progress,
                                      strokeWidth: 6,
                                    ),
                                  ),
                                  Text('${(_progress * 100).round()}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                ],
                              ),
                            ),
                          ),
                          if (completed) ...[
                            const SizedBox(height: 24),
                            Text(
                                'Оброблено завдань: ${_results.length}. '
                                'Можна надіслати результати на перевірку.',
                                textAlign: TextAlign.center),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 24),
                            Card(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(_error!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (completed)
                      FilledButton.icon(
                        key: const Key('send-results'),
                        onPressed: _sending ? null : _sendResults,
                        icon: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(_sending
                            ? 'Надсилання…'
                            : 'Send results to server'),
                      )
                    else if (!_loading)
                      FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Спробувати ще раз'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
