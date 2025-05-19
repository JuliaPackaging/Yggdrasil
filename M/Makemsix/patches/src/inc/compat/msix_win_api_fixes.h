// msix_mingw_fixes.h
// Comprehensive fixes for MinGW cross-compilation

#ifndef MSIX_MINGW_FIXES_H
#define MSIX_MINGW_FIXES_H

// =================================================================
// First, include Windows headers we need
// =================================================================
#include <windows.h>

// =================================================================
// Define a flag to indicate we're using MinGW
// =================================================================
#define MSIX_USING_MINGW 1

// =================================================================
// Fix the IID conflicts by preventing redefinitions
// =================================================================

// These macros prevent AppxPackaging.hpp from redefining IIDs
// that are already defined by Windows headers
#define MSIX_ALREADY_DEFINED_IIDS

// Define these to prevent AppxPackaging.hpp from defining them
#define MSIX_SKIP_IID_IUNKNOWN 1
#define MSIX_SKIP_IID_ISEQUENTIALSTREAM 1
#define MSIX_SKIP_IID_ISTREAM 1
#define MSIX_SKIP_IID_IAPPXFACTORY 1
#define MSIX_SKIP_IID_IAPPXPACKAGEREADER 1
#define MSIX_SKIP_IID_IAPPXPACKAGEWRITER 1
#define MSIX_SKIP_IID_IAPPXFILE 1
#define MSIX_SKIP_IID_IAPPXFILESENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXBLOCKAPREADER 1
#define MSIX_SKIP_IID_IAPPXBLOCKAMAPFILE 1
#define MSIX_SKIP_IID_IAPPXBLOCKAMAPFILESENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXBLOCKAMAPBLOCK 1
#define MSIX_SKIP_IID_IAPPXBLOCKAMAPBLOCKSENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXMANIFESTREADER 1
#define MSIX_SKIP_IID_IAPPXMANIFESTPACKAGEID 1
#define MSIX_SKIP_IID_IAPPXMANIFESTPROPERTIES 1
#define MSIX_SKIP_IID_IAPPXMANIFESTRESOURCESENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXMANIFESTDEVICECAPABILITIESENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXMANIFESTCAPABILITIESENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXMANIFESTAPPLICATIONSENUMERATOR 1
#define MSIX_SKIP_IID_IAPPXMANIFESTAPPLICATION 1

// =================================================================
// Modify the MSIX_INTERFACE macro to avoid duplicates
// =================================================================

// We'll add this to the top of AppxPackaging.hpp to prevent conflicts
#define MSIX_INTERFACE_FIXED(name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
    template<>                                               \
    struct UuidOfImpl<name>                                  \
    {                                                        \
        static constexpr const IID& iid = IID_##name;        \
    };

// =================================================================
// COM memory allocation functions for MinGW
// =================================================================
#ifndef CoTaskMemAlloc_DEFINED
#define CoTaskMemAlloc_DEFINED
inline LPVOID MinGW_CoTaskMemAlloc(SIZE_T cb) {
    return HeapAlloc(GetProcessHeap(), 0, cb);
}
#define CoTaskMemAlloc MinGW_CoTaskMemAlloc
#endif

#ifndef CoTaskMemFree_DEFINED
#define CoTaskMemFree_DEFINED
inline void MinGW_CoTaskMemFree(LPVOID pv) {
    if (pv) HeapFree(GetProcessHeap(), 0, pv);
}
#define CoTaskMemFree MinGW_CoTaskMemFree
#endif

#ifndef CoTaskMemRealloc_DEFINED
#define CoTaskMemRealloc_DEFINED
inline LPVOID MinGW_CoTaskMemRealloc(LPVOID pv, SIZE_T cb) {
    if (!pv) return CoTaskMemAlloc(cb);
    return HeapReAlloc(GetProcessHeap(), 0, pv, cb);
}
#define CoTaskMemRealloc MinGW_CoTaskMemRealloc
#endif

// =================================================================
// Fix FILETIME definition
// =================================================================
#ifndef MSIX_FILETIME_DEFINED
#define MSIX_FILETIME_DEFINED
typedef struct tagMSIX_FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} MSIX_FILETIME;
#endif

#ifndef FILETIME_TYPE
#define FILETIME_TYPE MSIX_FILETIME
#endif

#endif // MSIX_MINGW_FIXES_H
