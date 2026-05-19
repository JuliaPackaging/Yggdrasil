# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# Inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# Example: julia build_tarballs.jl --verbose --debug x86_64-linux-gnu

using BinaryBuilder, Pkg

name = "PARI"
version = v"2.17.3"

sources = [
    ArchiveSource(
        "https://pari.math.u-bordeaux.fr/pub/pari/unix/pari-$(version).tar.gz",
        "8d9c4fcd584c468d27e0f23c36836587284452094c4b1c404c20c4b810462dcb",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pari-*

# PARI's Configure expects target_host in the form "arch-osname"
# (its config/get_archos splits on the LAST dash). BB triplets like
# x86_64-linux-gnu have an extra component, so we normalise them.
case "${target}" in
    *-linux-*)         pari_host="$(echo ${target} | cut -d- -f1)-linux" ;;
    *-apple-darwin*)   pari_host="$(echo ${target} | cut -d- -f1)-darwin" ;;
    *-freebsd*)        pari_host="$(echo ${target} | cut -d- -f1)-freebsd" ;;
    *-mingw32*)        pari_host="$(echo ${target} | cut -d- -f1)-mingw" ;;
    *)                 pari_host="${target}" ;;
esac

# Cross-compile friendly Configure invocation.
#   --kernel=gmp  : skip native CPU kernel autodetect, always use GMP kernel
#   --graphic=none: do not link any plotting backend
#   --without-readline : no readline dep (libpari is what JLL consumers want)
#   --mt=pthread  : enable parboundary threading (matches Nemo/Hecke usage)
./Configure \
    --prefix=${prefix} \
    --host=${pari_host} \
    --with-gmp=${prefix} \
    --without-readline \
    --graphic=none \
    --kernel=gmp \
    --mt=pthread \
    --time=clock_gettime

# Configure creates an Oxxx-pthread/ directory; cd in and build.
cd O*
make -j${nproc} gp
make install
make install-lib-dyn

install_license ${WORKSPACE}/srcdir/pari-*/COPYING
"""

# Restricted to x86 Linux only for v1: PARI's Configure runs compiled test
# binaries to verify the toolchain, which fails under cross-compilation
# whenever the produced binary cannot run on the BB Linux sandbox (i.e.
# everywhere except native x86 Linux). Keep the broader pattern below as
# commented references for follow-up work.
platforms = [
    Platform("i686",   "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686",   "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
]
# platforms = supported_platforms()
# Windows (mingw) needs extra work in PARI's Configure → defer to a follow-up.
# platforms = filter(p -> !Sys.iswindows(p), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gp", :gp),
    LibraryProduct("libpari", :libpari),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"10")
