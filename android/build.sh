#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANDROID_DIR="$PROJECT_ROOT/android"

ANDROID_PLATFORM=${ANDROID_PLATFORM:-android-21}
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
BUILD_DIR="$ANDROID_DIR/build"
CACTUS_CURL_ROOT=${CACTUS_CURL_ROOT:-"$PROJECT_ROOT/libs/curl"}

if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -n "$ANDROID_HOME" ]; then
        ANDROID_NDK_HOME=$(ls -d "$ANDROID_HOME/ndk/"* 2>/dev/null | sort -V | tail -1)
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        ANDROID_NDK_HOME=$(ls -d "$HOME/Library/Android/sdk/ndk/"* 2>/dev/null | sort -V | tail -1)
    fi
fi

if [ -z "$ANDROID_NDK_HOME" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Error: Android NDK not found."
    echo "Set ANDROID_NDK_HOME or install NDK via Android SDK Manager"
    exit 1
fi

echo "Using NDK: $ANDROID_NDK_HOME"
CMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake"

if ! command -v cmake &> /dev/null; then
    echo "Error: cmake not found, please install it"
    exit 1
fi

n_cpu=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)

# StudyReels: build both ABIs. arm64-v8a keeps the flat output paths the
# StudyReels CI has always staged (android/libcactus_engine.so); x86_64
# goes to android/x86_64/ for the emulator E2E job (the x86_64 emulator's
# package manager extracts only device-ABI libs, so an arm64-only APK can
# never load the engine there). Per-ABI build dirs: CMake caches the ABI,
# so one shared dir would misbuild the second ABI.
for ABI in arm64-v8a x86_64; do
  ABI_BUILD_DIR="$BUILD_DIR-$ABI"
  if [ "$ABI" = "arm64-v8a" ]; then
    OUT_DIR="$ANDROID_DIR"
  else
    OUT_DIR="$ANDROID_DIR/$ABI"
    mkdir -p "$OUT_DIR"
  fi

  echo "Building Cactus for Android ($ABI)..."
  echo "Build type: $CMAKE_BUILD_TYPE"
  echo "Using $n_cpu CPU cores"
  echo "Android CMakeLists.txt: $ANDROID_DIR/CMakeLists.txt"
  echo "Vendored libcurl root: $CACTUS_CURL_ROOT"

  cmake -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
        -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
        -DCACTUS_CURL_ROOT="$CACTUS_CURL_ROOT" \
        -S "$ANDROID_DIR" \
        -B "$ABI_BUILD_DIR" >/dev/null

  cmake --build "$ABI_BUILD_DIR" --config "$CMAKE_BUILD_TYPE" -j "$n_cpu" >/dev/null

  cp "$ABI_BUILD_DIR/lib/libcactus.so" "$OUT_DIR/" 2>/dev/null || \
     cp "$ABI_BUILD_DIR/libcactus.so" "$OUT_DIR" 2>/dev/null || \
     { echo "Error: Could not find libcactus.so for $ABI"; exit 1; }

  # StudyReels stages the lib as libcactus_engine.so (the name its Dart FFI
  # opens); emit it under that name too.
  cp "$OUT_DIR/libcactus.so" "$OUT_DIR/libcactus_engine.so"

  cp "$ABI_BUILD_DIR/lib/libcactus_static.a" "$OUT_DIR/libcactus.a" 2>/dev/null || \
     cp "$ABI_BUILD_DIR/libcactus_static.a" "$OUT_DIR/libcactus.a" 2>/dev/null || \
     { echo "Warning: Could not find libcactus_static.a for $ABI"; }

  echo "Build complete for $ABI!"
  echo "Shared library location: $OUT_DIR/libcactus.so"
  echo "Static library location: $OUT_DIR/libcactus.a"
done
