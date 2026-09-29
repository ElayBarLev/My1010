# Builds libqqwing_ffi, the QQWing Sudoku generator behind a C ABI for
# dart:ffi (see qqwing_ffi.h).
#
# Used by:
#   - Android: android/app/build.gradle.kts (externalNativeBuild), once per ABI.
#   - Linux / macOS / Windows hosts, headless (no GUI toolkit needed):
#       cmake -S src/qqwing -B build/native -DCMAKE_BUILD_TYPE=Release
#       cmake --build build/native --config Release
#     `flutter test` runs this automatically (test/helpers/qqwing_library.dart).
cmake_minimum_required(VERSION 3.10)
project(qqwing_ffi VERSION 1.3.4 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

add_library(qqwing_ffi SHARED
  qqwing_ffi.cpp
  vendor/qqwing.cpp
)

target_include_directories(qqwing_ffi PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/vendor
)

# Export only the functions marked QQWING_FFI_EXPORT.
set_target_properties(qqwing_ffi PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN ON
  POSITION_INDEPENDENT_CODE ON
  WINDOWS_EXPORT_ALL_SYMBOLS OFF
)

if(MSVC)
  target_compile_options(qqwing_ffi PRIVATE /W3)
else()
  # QQWing is third-party code; don't drown our own warnings in its own.
  set_source_files_properties(vendor/qqwing.cpp PROPERTIES COMPILE_OPTIONS -w)
  target_compile_options(qqwing_ffi PRIVATE -Wall -Wextra)
endif()

if(ANDROID)
  # 16 KB page alignment, required for Android 15+ devices.
  target_link_options(qqwing_ffi PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR ANDROID)
  # Fail at link time rather than at dlopen time on a missing symbol.
  target_link_options(qqwing_ffi PRIVATE "-Wl,--no-undefined")
endif()

option(QQWING_BUILD_TESTS "Build the native smoke test" OFF)
option(QQWING_SANITIZE "Build with AddressSanitizer + UBSan (GCC/Clang)" OFF)

if(QQWING_SANITIZE AND NOT MSVC)
  set(QQWING_SANITIZER_FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_compile_options(qqwing_ffi PRIVATE ${QQWING_SANITIZER_FLAGS})
  target_link_options(qqwing_ffi PRIVATE ${QQWING_SANITIZER_FLAGS})
endif()

if(QQWING_BUILD_TESTS)
  enable_testing()
  add_executable(qqwing_ffi_test test/qqwing_ffi_test.cpp)
  target_include_directories(qqwing_ffi_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
  target_link_libraries(qqwing_ffi_test PRIVATE qqwing_ffi)
  if(QQWING_SANITIZE AND NOT MSVC)
    target_compile_options(qqwing_ffi_test PRIVATE ${QQWING_SANITIZER_FLAGS})
    target_link_options(qqwing_ffi_test PRIVATE ${QQWING_SANITIZER_FLAGS})
  endif()
  add_test(NAME qqwing_ffi_test COMMAND qqwing_ffi_test)
endif()
