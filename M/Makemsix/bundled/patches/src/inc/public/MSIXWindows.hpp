//
//  Copyright (C) 2017 Microsoft.  All rights reserved.
//  See LICENSE file in the project root for full license information.
//
// This header defines the types used by Windows that are not defined in other platforms
#ifndef __appxwindows_hpp__
#define __appxwindows_hpp__

#include <cstdint>
#include <string>
#include <cstring>

// For MinGW, include the Windows headers directly
#define MSIX_API extern "C" __attribute__((visibility("default")))
//#define MSIX_API extern "C" __declspec(dllexport)
#define DECLSPEC_SELECTANY __declspec(selectany)

// Ensure proper Windows version for APIs
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0600 // Windows Vista or later
#endif

#ifndef WINVER
#define WINVER 0x0600
#endif

// Make sure NOMINMAX is defined to prevent min/max macro conflicts
#ifndef NOMINMAX
#define NOMINMAX
#endif

// Include the Windows headers directly
#include <windef.h>
#include <winbase.h>
#include <winnt.h>
#include <windows.h>
#include <objbase.h>
    
// Undefine min/max macros from windows.h
#undef max
#undef min

// Define MSIX-specific FILETIME to avoid conflicts
#ifndef MSIX_FILETIME_DEFINED
#define MSIX_FILETIME_DEFINED
typedef struct tagMSIX_FILETIME
{
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} MSIX_FILETIME;
#endif

// Use MSIX_FILETIME in place of FILETIME for our code
#define FILETIME_TYPE MSIX_FILETIME

#endif //__appxwindows_hpp__
