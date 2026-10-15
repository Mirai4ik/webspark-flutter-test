import 'coordinate.dart';
import 'path_task.dart';

class TaskResult {
  const TaskResult({required this.task, required this.path});

  final PathTask task;
  final List<Coordinate> path;

  String get pathDescription => path.join(' -> ');

  Map<String, dynamic> toApiJson() => {
        'id': task.id,
        'result': {
          'steps': [
            for (final point in path)
              {'x': point.x.toString(), 'y': point.y.toString()},
          ],
          'path': path.map((point) => '(${point.x},${point.y})').join('->'),
        },
      };
}
