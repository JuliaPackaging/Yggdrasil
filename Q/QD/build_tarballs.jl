using BinaryBuilder, Pkg

name = "QD"
version = v"2.3.24"

# Collection of sources required to build SDPA-QD
sources = [
    ArchiveSource("https://www.davidhbailey.com/dhbsoftware/qd-$(version).tar.gz",
                  "a47b6c73f86e6421e86a883568dd08e299b20e36c11a99bdfbe50e01bde60e38"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qd*

./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --prefix=${prefix} \
    --disable-fma \
    --disable-static \
    --enable-shared
make -j${nproc}
make install

install_license BSD-LBNL-License.doc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

# The Windows build doesn't work
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqd_f_main", :libqd_f_main),
    LibraryProduct("libqdmod", :libqdmod, dont_dlopen = true),
    LibraryProduct("libqd", :libqd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
