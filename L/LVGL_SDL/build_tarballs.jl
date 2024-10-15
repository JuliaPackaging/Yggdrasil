# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LVGL_SDL"
version = v"9.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lvgl/lv_port_pc_eclipse.git", "ba45efb68b125aa93237e7c75c51d4cd65fc10cf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd lv_port_pc_eclipse/
git submodule update --init --recursive
cd lvgl/
patch -p1 << "EOF"
diff --git a/env_support/cmake/custom.cmake b/env_support/cmake/custom.cmake
index e4cd36376..0e1d4b9d0 100644
--- a/env_support/cmake/custom.cmake
+++ b/env_support/cmake/custom.cmake
@@ -26,6 +26,7 @@ file(GLOB_RECURSE THORVG_SOURCES ${LVGL_ROOT_DIR}/src/libs/thorvg/*.cpp ${LVGL_R
 # Build LVGL library
 add_library(lvgl ${SOURCES})
 add_library(lvgl::lvgl ALIAS lvgl)
+target_link_libraries(lvgl lvgl_thorvg ${SDL2_LIBRARIES})
 
 target_compile_definitions(
   lvgl PUBLIC $<$<BOOL:${LV_LVGL_H_INCLUDE_SIMPLE}>:LV_LVGL_H_INCLUDE_SIMPLE>
@@ -49,7 +50,7 @@ if(NOT LV_CONF_BUILD_DISABLE_THORVG_INTERNAL)
     add_library(lvgl_thorvg ${THORVG_SOURCES})
     add_library(lvgl::thorvg ALIAS lvgl_thorvg)
     target_include_directories(lvgl_thorvg SYSTEM PUBLIC ${LVGL_ROOT_DIR}/src/libs/thorvg)
-    target_link_libraries(lvgl_thorvg PUBLIC lvgl)
+    #    target_link_libraries(lvgl_thorvg PUBLIC lvgl)
 endif()
 
 if(NOT (CMAKE_C_COMPILER_ID STREQUAL "MSVC"))
EOF

patch -p1 << "EOF"
diff --git a/src/drivers/sdl/lv_sdl_window.c b/src/drivers/sdl/lv_sdl_window.c
index df8a28e4e..40c5c0bcd 100644
--- a/src/drivers/sdl/lv_sdl_window.c
+++ b/src/drivers/sdl/lv_sdl_window.c
@@ -438,7 +438,12 @@ static void * sdl_draw_buf_realloc_aligned(void * ptr, size_t new_size)
     /* Size must be multiple of align, See: https://en.cppreference.com/w/c/memory/aligned_alloc */
 
 #define BUF_ALIGN (LV_DRAW_BUF_ALIGN < sizeof(void *) ? sizeof(void *) : LV_DRAW_BUF_ALIGN)
-    return aligned_alloc(BUF_ALIGN, LV_ALIGN_UP(new_size, BUF_ALIGN));
+    void* result;
+    if (posix_memalign(&result, BUF_ALIGN, LV_ALIGN_UP(new_size, BUF_ALIGN)) == 0)
+    {
+        return result;
+    }
+    return NULL;
 #else
     return _aligned_malloc(LV_ALIGN_UP(new_size, LV_DRAW_BUF_ALIGN), LV_DRAW_BUF_ALIGN);
 #endif /* _WIN32 */
EOF

cd ..
patch -p1 << "EOF"
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 78eaf02..1753f9f 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -1,6 +1,8 @@
 cmake_minimum_required(VERSION 3.10)
 project(lvgl)
 
+option(BUILD_SHARED_LIBS "Build shared libraries" ON)
+
 option(LV_USE_DRAW_SDL "Use SDL draw unit" OFF)
 option(LV_USE_LIBPNG "Use libpng to decode PNG" OFF)
 option(LV_USE_LIBJPEG_TURBO "Use libjpeg turbo to decode JPEG" OFF)
EOF

cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "linux"; libc="glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblvgl", :liblvgl),
    LibraryProduct("liblvgl_thorvg", :liblvgl_thorvg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
