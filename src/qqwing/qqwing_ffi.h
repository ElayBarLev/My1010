/*
 * C ABI over the QQWing Sudoku generator, consumed by dart:ffi
 * (lib/games/sudoku/ffi/). Bindings are generated from this header with
 * `dart run ffigen --config ffigen.yaml`.
 *
 * Memory contract: the caller owns every buffer. Nothing allocated here
 * crosses the boundary, so there is nothing for Dart to free, and no C++
 * exception ever escapes (errors are reported through the return value).
 */
#ifndef QQWING_FFI_H
#define QQWING_FFI_H

#include <stdint.h>

#if defined(_WIN32)
#define QQWING_FFI_EXPORT __declspec(dllexport)
#else
#define QQWING_FFI_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Number of cells in a board; puzzle/solution buffers hold this many. */
#define QQWING_CELL_COUNT 81

/* Difficulty levels accepted by qqwing_generate. */
#define QQWING_DIFFICULTY_HARD 0
#define QQWING_DIFFICULTY_VERY_HARD 1
#define QQWING_DIFFICULTY_EXTREME 2

/* Return codes of qqwing_generate. */
#define QQWING_OK 0
#define QQWING_ERROR_INVALID_ARGUMENT 1
#define QQWING_ERROR_GENERATION_FAILED 2
#define QQWING_ERROR_INTERNAL 3

/* How the returned puzzle rated when QQWing solved it. */
typedef struct QqwingStats {
  int32_t given_count;
  int32_t single_count;
  int32_t hidden_single_count;
  int32_t naked_pair_count;
  int32_t hidden_pair_count;
  int32_t pointing_pair_triple_count;
  int32_t box_line_reduction_count;
  int32_t guess_count;
  int32_t backtrack_count;
  /* Puzzles generated (and rated) before one matched the difficulty. */
  int32_t attempts;
} QqwingStats;

/*
 * Generates a puzzle with a unique solution at the requested difficulty.
 *
 * puzzle_out / solution_out: caller-owned buffers of QQWING_CELL_COUNT
 *   int32_t, row-major. Empty puzzle cells are 0, others 1-9.
 * stats_out: optional (may be NULL).
 * seed: seeds the generator, so the same seed yields the same puzzle on a
 *   given platform.
 *
 * Thread-safe: calls are serialised internally because QQWing draws from
 * the process-wide rand().
 *
 * Returns QQWING_OK, or an error code with the buffers left untouched.
 */
QQWING_FFI_EXPORT int32_t qqwing_generate(int32_t difficulty, uint32_t seed,
                                          int32_t *puzzle_out,
                                          int32_t *solution_out,
                                          QqwingStats *stats_out);

/* The bundled QQWing version, a static string (never free it). */
QQWING_FFI_EXPORT const char *qqwing_version(void);

#ifdef __cplusplus
}
#endif

#endif /* QQWING_FFI_H */
