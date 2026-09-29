// Native smoke test for the C ABI. Build with sanitizers to check memory:
//   cmake -S src/qqwing -B build/native-test -DQQWING_BUILD_TESTS=ON \
//         -DQQWING_SANITIZE=ON && cmake --build build/native-test && \
//   ctest --test-dir build/native-test --output-on-failure
#include <cstdio>
#include <cstring>

#include "qqwing_ffi.h"

static int failures = 0;

#define CHECK(cond)                                              \
  do {                                                           \
    if (!(cond)) {                                               \
      std::fprintf(stderr, "%s:%d: CHECK(%s) failed\n", __FILE__, \
                   __LINE__, #cond);                             \
      ++failures;                                                \
    }                                                            \
  } while (0)

static bool valid_solution(const int32_t *s) {
  for (int unit = 0; unit < 9; ++unit) {
    bool row[10] = {}, col[10] = {}, box[10] = {};
    for (int i = 0; i < 9; ++i) {
      const int r = s[unit * 9 + i];
      const int c = s[i * 9 + unit];
      const int b = s[(unit / 3 * 3 + i / 3) * 9 + unit % 3 * 3 + i % 3];
      if (r < 1 || r > 9 || c < 1 || c > 9 || b < 1 || b > 9) return false;
      if (row[r] || col[c] || box[b]) return false;
      row[r] = col[c] = box[b] = true;
    }
  }
  return true;
}

int main() {
  int32_t puzzle[QQWING_CELL_COUNT];
  int32_t solution[QQWING_CELL_COUNT];

  for (int difficulty = QQWING_DIFFICULTY_HARD;
       difficulty <= QQWING_DIFFICULTY_EXTREME; ++difficulty) {
    for (uint32_t seed = 1; seed <= 3; ++seed) {
      QqwingStats stats;
      std::memset(&stats, 0, sizeof stats);
      CHECK(qqwing_generate(difficulty, seed, puzzle, solution, &stats) ==
            QQWING_OK);
      CHECK(valid_solution(solution));
      int givens = 0;
      for (int i = 0; i < QQWING_CELL_COUNT; ++i) {
        if (puzzle[i] != 0) {
          ++givens;
          CHECK(puzzle[i] == solution[i]);
        }
      }
      CHECK(givens == stats.given_count);
      CHECK(stats.attempts >= 1);
      if (difficulty == QQWING_DIFFICULTY_HARD) CHECK(stats.guess_count == 0);
      if (difficulty == QQWING_DIFFICULTY_VERY_HARD) {
        CHECK(stats.guess_count >= 1 && stats.guess_count <= 2);
      }
      if (difficulty == QQWING_DIFFICULTY_EXTREME) CHECK(stats.guess_count >= 3);
      std::printf("difficulty %d seed %u: %d givens, %d guesses, %d attempts\n",
                  difficulty, seed, stats.given_count, stats.guess_count,
                  stats.attempts);
    }
  }

  // Same seed, same puzzle.
  int32_t again[QQWING_CELL_COUNT];
  CHECK(qqwing_generate(QQWING_DIFFICULTY_HARD, 7, puzzle, solution, nullptr) ==
        QQWING_OK);
  CHECK(qqwing_generate(QQWING_DIFFICULTY_HARD, 7, again, solution, nullptr) ==
        QQWING_OK);
  CHECK(std::memcmp(puzzle, again, sizeof puzzle) == 0);

  // Bad arguments are rejected without touching the buffers.
  std::memset(puzzle, 0x7f, sizeof puzzle);
  CHECK(qqwing_generate(3, 1, puzzle, solution, nullptr) ==
        QQWING_ERROR_INVALID_ARGUMENT);
  CHECK(qqwing_generate(-1, 1, puzzle, solution, nullptr) ==
        QQWING_ERROR_INVALID_ARGUMENT);
  CHECK(qqwing_generate(0, 1, nullptr, solution, nullptr) ==
        QQWING_ERROR_INVALID_ARGUMENT);
  CHECK(qqwing_generate(0, 1, puzzle, nullptr, nullptr) ==
        QQWING_ERROR_INVALID_ARGUMENT);
  CHECK(puzzle[0] == 0x7f7f7f7f);

  CHECK(std::strcmp(qqwing_version(), "1.3.4") == 0);

  if (failures == 0) std::printf("all checks passed\n");
  return failures == 0 ? 0 : 1;
}
