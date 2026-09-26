# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function yggdrasil_version(version::VersionNumber, offset::VersionNumber)
    max_offset = v"10.100.1000"
    @assert offset < max_offset
    VersionNumber(
        max_offset.major * version.major + offset.major,
        max_offset.minor * version.minor + offset.minor,
        max_offset.patch * version.patch + offset.patch
    )
end

name = "libsixel"
version = v"1.8.7"
ygg_offset = v"0.0.2"  # NOTE: increase on new build, reset on new upstream version
ygg_version = yggdrasil_version(version, ygg_offset)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/saitoha/libsixel.git", "764f4e618c8bbc427fb74622e3227243fe6762fb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsixel

update_configure_scripts

# `AC_FUNC_MALLOC`/`AC_FUNC_REALLOC` guess the `malloc(0)` result from a table of
# OS names when cross-compiling; it lists neither musl nor Darwin, and the
# `rpl_*` replacements it selects go undeclared in src/frame.c.  Every platform
# we build returns non-NULL from `malloc(0)`, so just answer the check.
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --includedir=$WORKSPACE/destdir/include \
    --libdir=$WORKSPACE/destdir/lib \
    --enable-python=no \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsixel", :libsixel)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
