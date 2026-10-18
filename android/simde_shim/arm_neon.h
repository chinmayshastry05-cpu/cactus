// x86_64-only shim (StudyReels): the Cactus kernels #include <arm_neon.h>
// unconditionally, but x86_64 has no <arm_neon.h>. This shim forwards the
// NEON API to SIMDe (header-only; translates NEON intrinsics to SSE/AVX).
// It is added to the include path ONLY for the Android x86_64 build; the
// arm64 build uses the real <arm_neon.h> and is untouched.
//
// x86_64 clang treats __fp16 (storage-only, cannot be a return type) and
// _Float16 (arithmetic) as distinct types, while SIMDe's fp16 API uses
// _Float16. Unify them so the kernels' __fp16 buffers match SIMDe.
#pragma once
#define __fp16 _Float16
#define SIMDE_ENABLE_NATIVE_ALIASES
#include "simde/arm/neon.h"

// The kernel passes bare vsqrtq_f32 as a function pointer, but SIMDe
// defines vsqrtq_f32 as a function-like macro (which only expands when
// followed by '('), so the bare identifier is undeclared. Undef the macro
// and provide a real forwarding function so the bare identifier resolves.
#undef vsqrtq_f32
static inline simde_float32x4_t vsqrtq_f32(simde_float32x4_t a) {
    return simde_vsqrtq_f32(a);
}

// SIMDe's native aliases cover the plain vector types but not the
// multi-vector struct types (x2/x3/x4) the kernels use (vld2/vst2/vtrn).
// Alias the three struct types the engine uses to SIMDe's equivalents.
typedef simde_float16x8x2_t float16x8x2_t;
typedef simde_float32x4x2_t float32x4x2_t;
typedef simde_int8x16x4_t int8x16x4_t;
