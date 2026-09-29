#include "qqwing_ffi.h"

#include <cstdlib>
#include <mutex>
#include <new>

#include "config.h"
#include "qqwing.hpp"

namespace {

using qqwing::BOARD_SIZE;
using qqwing::SudokuBoard;

static_assert(BOARD_SIZE == QQWING_CELL_COUNT, "board size mismatch");

// Upper bound on puzzles generated per call. The rarest level (Extreme)
// matches about one puzzle in ten, so this is never reached in practice;
// it only guarantees the call terminates.
constexpr int kMaxAttempts = 2000;

// QQWing shuffles with the process-wide rand(), so concurrent calls (from
// several Dart isolates) would interleave draws and break seeding.
std::mutex generate_mutex;

// QQWing rates puzzles Simple / Easy / Intermediate / Expert. The app's
// three levels map onto the hard end of that scale:
//   Hard      - Intermediate: needs pairs / pointing / box-line reductions,
//               but never a guess.
//   Very Hard - Expert with one or two guesses.
//   Extreme   - Expert with three or more guesses.
bool matches(int32_t difficulty, SudokuBoard &board) {
  const SudokuBoard::Difficulty rating = board.getDifficulty();
  const int guesses = board.getGuessCount();
  switch (difficulty) {
    case QQWING_DIFFICULTY_HARD:
      return rating == SudokuBoard::INTERMEDIATE;
    case QQWING_DIFFICULTY_VERY_HARD:
      return rating == SudokuBoard::EXPERT && guesses <= 2;
    case QQWING_DIFFICULTY_EXTREME:
      return rating == SudokuBoard::EXPERT && guesses >= 3;
    default:
      return false;
  }
}

void fill_stats(SudokuBoard &board, int32_t attempts, QqwingStats *stats) {
  stats->given_count = board.getGivenCount();
  stats->single_count = board.getSingleCount();
  stats->hidden_single_count = board.getHiddenSingleCount();
  stats->naked_pair_count = board.getNakedPairCount();
  stats->hidden_pair_count = board.getHiddenPairCount();
  stats->pointing_pair_triple_count = board.getPointingPairTripleCount();
  stats->box_line_reduction_count = board.getBoxLineReductionCount();
  stats->guess_count = board.getGuessCount();
  stats->backtrack_count = board.getBacktrackCount();
  stats->attempts = attempts;
}

}  // namespace

extern "C" {

int32_t qqwing_generate(int32_t difficulty, uint32_t seed, int32_t *puzzle_out,
                        int32_t *solution_out, QqwingStats *stats_out) {
  if (puzzle_out == nullptr || solution_out == nullptr ||
      difficulty < QQWING_DIFFICULTY_HARD ||
      difficulty > QQWING_DIFFICULTY_EXTREME) {
    return QQWING_ERROR_INVALID_ARGUMENT;
  }

  // An exception unwinding into Dart would abort the process, so nothing
  // may escape this function.
  try {
    std::lock_guard<std::mutex> lock(generate_mutex);
    std::srand(seed);

    // RAII: the board (and its solve history) is freed on every path.
    SudokuBoard board;
    // Needed for the difficulty rating below.
    board.setRecordHistory(true);

    for (int attempt = 1; attempt <= kMaxAttempts; ++attempt) {
      // No symmetry: symmetric puzzles keep extra givens and rarely rate
      // Expert.
      if (!board.generatePuzzleSymmetry(SudokuBoard::NONE)) continue;
      if (!board.solve() || !board.isSolved()) continue;
      if (!matches(difficulty, board)) continue;

      const int *puzzle = board.getPuzzle();
      const int *solution = board.getSolution();
      for (int i = 0; i < BOARD_SIZE; ++i) {
        puzzle_out[i] = static_cast<int32_t>(puzzle[i]);
        solution_out[i] = static_cast<int32_t>(solution[i]);
      }
      if (stats_out != nullptr) fill_stats(board, attempt, stats_out);
      return QQWING_OK;
    }
    return QQWING_ERROR_GENERATION_FAILED;
  } catch (const std::bad_alloc &) {
    return QQWING_ERROR_INTERNAL;
  } catch (...) {
    return QQWING_ERROR_INTERNAL;
  }
}

const char *qqwing_version(void) {
  // qqwing::getVersion() returns a std::string by value; hand out the
  // underlying literal instead so the pointer outlives the call.
  return VERSION;
}

}  // extern "C"
