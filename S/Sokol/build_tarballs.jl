using BinaryBuilder

name = "Sokol"
version = v"2024.1.1"  # Use the commit date or tag of Sokol you're targeting

# Use the latest commit or a specific tag from the Sokol repository
sources = [
    GitSource("https://github.com/floooh/sokol.git", "db9ebdf24243572c190affde269b92725942ddd0"),  # Replace with actual commit
]

# Build script
script = raw"""
cd $WORKSPACE/srcdir/sokol*
export CFLAGS="-I${includedir}"
touch CMakeLists.txt
touch sokol.c

cat >> sokol.c <<EOF
#define SOKOL_IMPL
#if defined(_MSC_VER)
#define SOKOL_D3D11
#define SOKOL_LOG(str) OutputDebugStringA(str)
#elif defined(__EMSCRIPTEN__)
#define SOKOL_GLES2
#elif defined(__APPLE__)
// NOTE: on macOS, sokol.c is compiled explicitly as ObjC 
#include <TargetConditionals.h>
#define SOKOL_METAL
#else
#define SOKOL_GLCORE
#endif

#define SOKOL_WIN32_FORCE_MAIN
#include "sokol_audio.h"
#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_time.h"
#include "sokol_glue.h"
#include "sokol_fetch.h"
#include "sokol_log.h"
#include "sokol_args.h"
EOF

cat >> CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.0)
project(game)
set(CMAKE_C_STANDARD 11)
if (CMAKE_SYSTEM_NAME STREQUAL Emscripten)
    set(CMAKE_EXECUTABLE_SUFFIX ".html")
endif()

# Linux -pthread shenanigans
if (CMAKE_SYSTEM_NAME STREQUAL Linux)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
endif()

#=== LIBRARY: sokol
# add headers to the the file list because they are useful to have in IDEs
set(SOKOL_HEADERS
    sokol_gfx.h
    sokol_app.h
    sokol_audio.h
    sokol_time.h
    sokol_glue.h
    sokol_log.h
    sokol_args.h
    sokol_fetch.h
    )
add_library(sokol SHARED sokol.c ${SOKOL_HEADERS})
if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(exe_type MACOSX_BUNDLE)    
    # compile sokol.c as Objective-C
    target_compile_options(sokol PRIVATE -x objective-c)
    target_link_libraries(sokol
        "-framework QuartzCore"
        "-framework Cocoa"
        "-framework MetalKit"
        "-framework Metal"
        "-framework AudioToolbox")
else()
    if (CMAKE_SYSTEM_NAME STREQUAL Linux)
        target_link_libraries(sokol INTERFACE X11 Xi Xcursor GL asound dl m)
        target_link_libraries(sokol PUBLIC Threads::Threads)
    endif()
    if(CMAKE_SYSTEM_NAME STREQUAL Windows)
        set(exe_type WIN32)
    endif()
endif()
target_include_directories(sokol INTERFACE sokol)
EOF

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build

install -Dm 755 "build/libsokol.${dlext}" "${libdir}/libsokol.${dlext}"
install -Dm 755 "sokol_gfx.h" "${includedir}/sokol_gfx.h"
install -Dm 755 "sokol_app.h" "${includedir}/sokol_app.h"
install -Dm 755 "sokol_audio.h" "${includedir}/sokol_audio.h"
install -Dm 755 "sokol_time.h" "${includedir}/sokol_time.h"
install -Dm 755 "sokol_glue.h" "${includedir}/sokol_glue.h"
install -Dm 755 "sokol_log.h" "${includedir}/sokol_log.h"
install -Dm 755 "sokol_args.h" "${includedir}/sokol_args.h"
install -Dm 755 "sokol_fetch.h" "${includedir}/sokol_fetch.h"
"""

# Supported platforms
platforms = supported_platforms(exclude=p->arch(p)=="armv6l"||Sys.isbsd(p)||arch(p)=="riscv64"||Sys.iswindows(p))

# Platform-specific dependencies
dependencies = [
    # Linux dependencies
    Dependency("Xorg_libX11_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXrandr_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXi_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXcursor_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Xorg_libXinerama_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("Libglvnd_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("xkbcommon_jll"; platforms=filter(Sys.islinux, platforms))
]

# Library products
products = [
    LibraryProduct("libsokol", :libsokol)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
