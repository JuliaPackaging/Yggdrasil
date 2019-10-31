# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "z3"
version = v"4.8.6"

# Collection of sources required to complete build
sources = [
    "https://github.com/Z3Prover/z3.git" =>
    "78ed71b8de7d4d089f2799bf2d06f411ac6b9062",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd z3/
cat <<END | patch -p1
diff --git a/src/util/memory_manager.cpp b/src/util/memory_manager.cpp
index 3fe71c5e3e..a325afca75 100644
--- a/src/util/memory_manager.cpp
+++ b/src/util/memory_manager.cpp
@@ -163,7 +163,7 @@ unsigned long long memory::get_max_used_memory() {
 }
 
 #if defined(_WINDOWS)
-#include <Windows.h>
+#include <windows.h>
 #endif
 
 unsigned long long memory::get_max_memory_size() {
END
cd ..
mkdir z3-build
cd z3-build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ../z3
make -j20
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libz3", :libz3),
    ExecutableProduct("bin/z3", :z3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

