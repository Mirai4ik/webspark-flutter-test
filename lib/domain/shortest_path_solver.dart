import 'coordinate.dart';
import 'path_task.dart';

class ShortestPathSolver {
  const ShortestPathSolver();

  static const List<(int, int)> _directions = [
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  List<Coordinate> solve(PathTask task) {
    final start = task.start;
    final end = task.end;

    if (!task.isInside(start) ||
        !task.isInside(end) ||
        task.isBlocked(start) ||
        task.isBlocked(end)) {
      return const [];
    }

    if (start == end) {
      return [start];
    }

    final queue = <Coordinate>[start];
    var head = 0;

    final previous = <Coordinate, Coordinate?>{
      start: null,
    };

    while (head < queue.length) {
      final current = queue[head++];

      for (final (dx, dy) in _directions) {
        // The API expects every visited cell, including cells on straight lines.
        final next = Coordinate(x: current.x + dx, y: current.y + dy);
        if (task.isBlocked(next) || previous.containsKey(next)) {
          continue;
        }
        previous[next] = current;
        if (next == end) {
          return _restorePath(previous, end);
        }
        queue.add(next);
      }
    }

    return const [];
  }

  List<Coordinate> _restorePath(
    Map<Coordinate, Coordinate?> previous,
    Coordinate end,
  ) {
    final path = <Coordinate>[];

    Coordinate? current = end;

    while (current != null) {
      path.add(current);
      current = previous[current];
    }

    return path.reversed.toList(growable: false);
  }
}
