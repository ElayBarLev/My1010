import 'dart:ffi';
import 'dart:io';

import 'qqwing_bindings.g.dart';

/// Opens the native QQWing library built from `src/qqwing/`.
///
/// - Android / Linux: `libqqwing_ffi.so` (Gradle's externalNativeBuild
///   packages it in the APK; on Linux it must be on the loader path).
/// - macOS: `libqqwing_ffi.dylib`; Windows: `qqwing_ffi.dll`.
/// - iOS: statically linked into the app, looked up in the process.
///
/// [path] overrides the location (tests point it at `build/native/`).
QqwingBindings openQqwing({String? path}) {
  final DynamicLibrary library;
  if (path != null) {
    library = DynamicLibrary.open(path);
  } else if (Platform.isIOS) {
    library = DynamicLibrary.process();
  } else if (Platform.isMacOS) {
    library = DynamicLibrary.open('libqqwing_ffi.dylib');
  } else if (Platform.isWindows) {
    library = DynamicLibrary.open('qqwing_ffi.dll');
  } else {
    library = DynamicLibrary.open('libqqwing_ffi.so');
  }
  if (!library.providesSymbol('qqwing_generate')) {
    throw ArgumentError('qqwing_generate is not exported by $library');
  }
  return QqwingBindings(library);
}
