---
name: windows-recipes
description: Rules for the Windows (mingw-w64) parts of Yggdrasil recipes. Use when a build fails or a product is missing only on Windows, or a build_tarballs.jl branches on *-mingw* or Sys.iswindows.
---

# Windows packages

The Windows targets, `x86_64-w64-mingw32` and `i686-w64-mingw32`, build with GCC or Clang against mingw-w64, not MSVC. Code that tests `_WIN32` but assumes MSVC (MSVC-only headers or intrinsics, `#pragma comment(lib, …)`) needs a patch to test `_MSC_VER` instead, or to add the library to the link line.

## Shared libraries

- **Location**: DLLs go in `${libdir}`, which is `${prefix}/bin` on Windows, and import libraries (`libfoo.dll.a`) in `${prefix}/lib`. CMake and libtool do this already; when upstream installs DLLs into `lib`, move them with `mv -v ${prefix}/lib/*.${dlext} ${libdir}/`.
- **libtool builds only a static library** unless the library links with `-no-undefined`; its log says `undefined symbols not allowed in x86_64-w64-mingw32 shared libraries; building static only`. Add `-no-undefined` to the library's `_la_LDFLAGS` with a patch to `Makefile.am`, run `autoreconf -fiv`, and report the patch upstream.
- **Product names**: libtool names DLLs `libfoo-N.dll`, and some projects drop the `lib` prefix. List each spelling: `LibraryProduct(["libfoo", "libfoo-1"], :libfoo)`.
- **Exports**: GNU ld exports every symbol of a DLL unless some object file marks one `__declspec(dllexport)` or a `.def` file is given; then it exports only those. When symbols are missing from the DLL, first define the macro upstream's export header expects for a shared build. Use `-Wl,--export-all-symbols` only when upstream has none.

## Compiling

- **Header case**: mingw-w64 headers are lowercase (`windows.h`, `winsock2.h`) on a case-sensitive file system, so `#include <Windows.h>` fails. Patch the include; don't add symlinks to the sys-root.
- **Windows API version**: when mingw-w64 has a function but the compiler reports it undeclared, `_WIN32_WINNT` is lower than the version that introduced it, often because upstream defines it. Raise it to that version, e.g. `-D_WIN32_WINNT=0x0601` for Windows 7.
- **System libraries**: when upstream's build system omits them, link the import libraries of the Windows APIs used, e.g. `-lws2_32` for sockets.

## Loading

- **"32 bit pseudo relocation out of range"** when x86_64 loads the DLL: try `-Wl,--disable-runtime-pseudo-reloc`, else link `-static-libstdc++ -static-libgcc`.
