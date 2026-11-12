using BinaryBuilder

name = "PCRE"
# 8.45 is the final release of the original PCRE (PCRE1); it is end-of-life and
# superseded by PCRE2.  We keep major.minor pinned to the upstream 8.45 release
# and bump the patch component to trigger fresh JLL builds (e.g. to add RISC-V).
version = v"8.45.1"

# Collection of sources required to build PCRE
sources = [
    ArchiveSource("https://sourceforge.net/projects/pcre/files/pcre/$(version.major).$(version.minor)/pcre-$(version.major).$(version.minor).tar.bz2",
                  "4dae6fdcd2bb0bb6c37b5f97c33c2be954da743985369cddac3546e3218bffb8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre-*/
# Note: we deliberately do not enable the JIT (--enable-jit): the bundled sljit in
# PCRE1 has no RISC-V backend, so enabling it would break riscv64.  We also drop
# the C++ wrapper (--disable-cpp); nothing in the ecosystem links libpcrecpp, and
# omitting it avoids the std::string GCC 4/5 ABI split entirely.
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-utf8 \
    --enable-unicode-properties \
    --disable-cpp \
    --disable-static
make -j${nproc} VERBOSE=1
make install VERBOSE=1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcre", :libpcre),
    LibraryProduct("libpcreposix", :libpcreposix),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
