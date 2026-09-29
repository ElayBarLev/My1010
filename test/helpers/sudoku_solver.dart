/// Counts the solutions of [grid] (0 = empty), stopping at [limit].
/// Independent of QQWing, to check the puzzles it generates.
int countSudokuSolutions(List<int> grid, {int limit = 2}) {
  final cells = [...grid];
  var count = 0;

  bool allowed(int index, int value) {
    final row = index ~/ 9, col = index % 9;
    final br = row ~/ 3 * 3, bc = col ~/ 3 * 3;
    for (var i = 0; i < 9; i++) {
      if (cells[row * 9 + i] == value || cells[i * 9 + col] == value) {
        return false;
      }
      if (cells[(br + i ~/ 3) * 9 + bc + i % 3] == value) return false;
    }
    return true;
  }

  void search() {
    // Branch on the empty cell with the fewest candidates.
    var best = -1;
    var bestOptions = <int>[];
    for (var i = 0; i < 81; i++) {
      if (cells[i] != 0) continue;
      final options = [
        for (var v = 1; v <= 9; v++)
          if (allowed(i, v)) v,
      ];
      if (options.isEmpty) return;
      if (best == -1 || options.length < bestOptions.length) {
        best = i;
        bestOptions = options;
      }
    }
    if (best == -1) {
      count++;
      return;
    }
    for (final v in bestOptions) {
      cells[best] = v;
      search();
      cells[best] = 0;
      if (count >= limit) return;
    }
  }

  search();
  return count;
}

/// Whether [solution] is a complete, valid Sudoku.
bool isValidSudokuSolution(List<int> solution) {
  for (var unit = 0; unit < 9; unit++) {
    final row = <int>{}, col = <int>{}, box = <int>{};
    for (var i = 0; i < 9; i++) {
      row.add(solution[unit * 9 + i]);
      col.add(solution[i * 9 + unit]);
      box.add(solution[(unit ~/ 3 * 3 + i ~/ 3) * 9 + unit % 3 * 3 + i % 3]);
    }
    for (final set in [row, col, box]) {
      if (set.length != 9 || set.any((v) => v < 1 || v > 9)) return false;
    }
  }
  return true;
}
