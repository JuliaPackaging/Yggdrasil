/* crash-handler calls _invoke_watson, which mingw-w64 v11 does not provide
   for msvcrt.dll. Terminate the process the way the UCRT does. */
#include <stdint.h>
#include <windows.h>
#include <intrin.h>

__declspec(noreturn) void __cdecl _invoke_watson(const wchar_t *expression,
                                                 const wchar_t *function,
                                                 const wchar_t *file,
                                                 unsigned int line,
                                                 uintptr_t reserved)
{
    __fastfail(FAST_FAIL_INVALID_ARG);
}
