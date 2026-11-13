/* Access to this module's memory for a caller that has none of its own here (another Wasm module,
   or a host), by address: loads and stores of 8, 32 and 64 bits. With `malloc` and `free`, which
   the module also exports, a caller stages the buffers PCRE2's functions take. */
#include <stdint.h>
#include <string.h>

#define EXPORT(name) __attribute__((export_name(#name))) name

uint32_t EXPORT(mem_load8)(uint32_t a) { return *(const uint8_t *)(uintptr_t)a; }
uint32_t EXPORT(mem_load32)(uint32_t a) { uint32_t v; memcpy(&v, (const void *)(uintptr_t)a, 4); return v; }
uint64_t EXPORT(mem_load64)(uint32_t a) { uint64_t v; memcpy(&v, (const void *)(uintptr_t)a, 8); return v; }
void EXPORT(mem_store8)(uint32_t a, uint32_t v) { *(uint8_t *)(uintptr_t)a = (uint8_t)v; }
void EXPORT(mem_store32)(uint32_t a, uint32_t v) { memcpy((void *)(uintptr_t)a, &v, 4); }
void EXPORT(mem_store64)(uint32_t a, uint64_t v) { memcpy((void *)(uintptr_t)a, &v, 8); }
