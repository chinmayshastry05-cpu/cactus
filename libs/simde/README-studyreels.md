SIMDe (SIMD Everywhere) v0.8.2, vendored headers only.
Source: https://github.com/simd-everywhere/simde (tag v0.8.2).
License: MIT (see the license header in each file under simde/).
Used ONLY by the Android x86_64 build (emulator E2E): it translates the
Cactus kernels' ARM NEON intrinsics to SSE/AVX. The arm64 build does
not use SIMDe. Headers are unmodified upstream files.
