#if defined(IS_FOR_PYTIGRE) || defined(IS_FOR_JULIA_TIGRE)
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "TIGRE_common.hpp"
#if defined(IS_FOR_JULIA_TIGRE)
#include "tigre_julia_runtime.hpp"
#endif
void mexPrintf(const char* format, ...) {
    PRINT_HERE("");
    va_list argpointer;
    va_start(argpointer, format);
    vprintf(format, argpointer);
    va_end(argpointer);
}
void mexErrMsgIdAndTxt(const char* pcTag, const char* pcMsg) {
#if defined(IS_FOR_JULIA_TIGRE)
    tigre_julia_throw(pcTag, pcMsg);
#else
    PRINT_HERE("%s %s\n", pcTag, pcMsg);
    exit(1);
#endif
}
void mexWarnMsgIdAndTxt(const char* pcTag, const char* pcMsg) {
    PRINT_HERE("%s %s\n", pcTag, pcMsg);
}
#endif  // IS_FOR_PYTIGRE || IS_FOR_JULIA_TIGRE
