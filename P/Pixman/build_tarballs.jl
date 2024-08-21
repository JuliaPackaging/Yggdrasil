using BinaryBuilder, Pkg

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.43.4"

sources = [
    ArchiveSource("https://www.cairographics.org/releases/pixman-$(version).tar.gz",
                  "a0624db90180c7ddb79fc7a9151093dc37c646d8c38d3f232f767cf64b85a226"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pixman-*

# Define `generic_blt`; see
# <https://lists.freedesktop.org/archives/pixman/2023-February/005002.html>
# and
# <https://gitlab.freedesktop.org/rth7680/pixman/-/tree/general>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/general_blt.patch

mkdir build && cd build
meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release -Dtests=disabled -Ddemos=disabled ..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpixman-1", :libpixman)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
