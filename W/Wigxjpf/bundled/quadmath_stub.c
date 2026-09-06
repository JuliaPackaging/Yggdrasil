/*
 * Stub implementation for platforms without quadmath support
 * This file provides error stubs for float128 functions on platforms
 * where libquadmath is not available (e.g., macOS, ARM Linux)
 */

#include <stdio.h>
#include <stdlib.h>

__attribute__((noreturn)) static void
float128_not_available(const char *func_name) {
  fprintf(
      stderr,
      "\n"
      "ERROR: %s is not available on this platform.\n"
      "\n"
      "This platform does not support __float128 (128-bit floating point).\n"
      "Available precision levels:\n"
      "  - double (64-bit): Use wig3jj() and similar functions\n"
      "  - long double (80/128-bit): Use wig3jj_long_double() if available\n"
      "\n"
      "float128 support is only available on x86/x86_64 Linux and Windows.\n"
      "\n",
      func_name);
  abort();
}

// Forward declarations (we can't use __float128 here, so use a placeholder)
typedef long double float128_placeholder;
struct wigxjpf_temp;

// Stub implementations for all float128 functions
// Based on wigxjpf_quadmath.h

/* Simplified interface */

void wig3jj_float128(float128_placeholder *result, int two_j1, int two_j2,
                     int two_j3, int two_m1, int two_m2, int two_m3) {
  float128_not_available("wig3jj_float128");
}

void wig6jj_float128(float128_placeholder *result, int two_j1, int two_j2,
                     int two_j3, int two_j4, int two_j5, int two_j6) {
  float128_not_available("wig6jj_float128");
}

void wig9jj_float128(float128_placeholder *result, int two_j1, int two_j2,
                     int two_j3, int two_j4, int two_j5, int two_j6, int two_j7,
                     int two_j8, int two_j9) {
  float128_not_available("wig9jj_float128");
}

/* Normal interface */

void calc_3j_float128(float128_placeholder *result, int two_j1, int two_j2,
                      int two_j3, int two_m1, int two_m2, int two_m3,
                      struct wigxjpf_temp *temp) {
  float128_not_available("calc_3j_float128");
}

void calc_6j_float128(float128_placeholder *result, int two_j1, int two_j2,
                      int two_j3, int two_j4, int two_j5, int two_j6,
                      struct wigxjpf_temp *temp) {
  float128_not_available("calc_6j_float128");
}

void calc_9j_float128(float128_placeholder *result, int two_j1, int two_j2,
                      int two_j3, int two_j4, int two_j5, int two_j6,
                      int two_j7, int two_j8, int two_j9,
                      struct wigxjpf_temp *temp) {
  float128_not_available("calc_9j_float128");
}
