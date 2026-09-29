import 'dart:io';

/// Builds `src/qqwing` with CMake into `build/native` (incremental, so it is
/// a no-op when nothing changed) and returns the shared library's path.
///
/// Returns `null` when CMake isn't installed, so FFI tests are skipped on
/// such machines; on CI (`CI` set) that is an error instead.
String? buildQqwingLibrary() {
  const buildDir = 'build/native';
  try {
    _run('cmake', [
      '-S',
      'src/qqwing',
      '-B',
      buildDir,
      '-DCMAKE_BUILD_TYPE=Release',
    ]);
  } on ProcessException {
    if (Platform.environment.containsKey('CI')) rethrow;
    return null;
  }
  _run('cmake', ['--build', buildDir, '--config', 'Release']);

  final name = Platform.isWindows
      ? 'qqwing_ffi.dll'
      : Platform.isMacOS
      ? 'libqqwing_ffi.dylib'
      : 'libqqwing_ffi.so';
  // Multi-config generators (Visual Studio, Xcode) add a config folder.
  for (final candidate in ['$buildDir/$name', '$buildDir/Release/$name']) {
    if (File(candidate).existsSync()) return File(candidate).absolute.path;
  }
  throw StateError('CMake did not produce $name in $buildDir');
}

void _run(String executable, List<String> args) {
  final result = Process.runSync(executable, args);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      args,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
}
