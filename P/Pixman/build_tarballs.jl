using BinaryBuilder, Pkg

# Collection of sources required to build Pixman
name = "Pixman"
version = v"0.42.2"

sources = [
    ArchiveSource("https://www.cairographics.org/releases/pixman-$(version).tar.gz",
                  "ea1480efada2fd948bc75366f7c349e1c96d3297d09a3fe62626e38e234a625e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pixman-*/

# Define `generic_blt`; see
# <https://lists.freedesktop.org/archives/pixman/2023-February/005002.html>
# and
# <https://gitlab.freedesktop.org/rth7680/pixman/-/tree/general>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/general_blt.patch

args=(--prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static)
if [[ ${target} == aarch64-apple-darwin* ]]; then
    # Work around a but; see
    # <https://lists.freedesktop.org/archives/pixman/2023-February/005002.html>
    # and
    # <https://gitlab.freedesktop.org/rth7680/pixman/-/tree/general>
    args+=(--disable-arm-a64-neon --disable-arm-neon)
fi

./configure ${args[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
