# QQWing (vendored) + C wrapper for dart:ffi

- `vendor/`: QQWing 1.3.4 C++ sources, copied unmodified from
  <https://github.com/stephenostermiller/qqwing> (commit `6048c90`), except
  `config.h`, which replaces the autotools-generated header.
  **License: GPL-2.0-or-later** (`vendor/COPYING`). Distributing the app with
  this library linked in means distributing it under GPL-compatible terms.
- `qqwing_ffi.h` / `qqwing_ffi.cpp`: the C ABI the app calls. Buffers are
  caller-owned, no exception crosses the boundary, calls are serialised.
- `CMakeLists.txt`: builds `libqqwing_ffi` for Android (via
  `android/app/build.gradle.kts`) and for Linux / macOS / Windows hosts,
  headless:

  ```bash
  cmake -S src/qqwing -B build/native -DCMAKE_BUILD_TYPE=Release
  cmake --build build/native --config Release
  ```

  `flutter test` does this automatically (`test/helpers/qqwing_library.dart`).
- Native smoke test under AddressSanitizer / UBSan / LeakSanitizer:

  ```bash
  cmake -S src/qqwing -B build/native-test -DCMAKE_BUILD_TYPE=Debug \
        -DQQWING_BUILD_TESTS=ON -DQQWING_SANITIZE=ON
  cmake --build build/native-test && ctest --test-dir build/native-test
  ```

After changing `qqwing_ffi.h`, regenerate the Dart bindings
(`lib/games/sudoku/ffi/qqwing_bindings.g.dart`):

```bash
dart run ffigen --config ffigen.yaml && dart format lib
```
