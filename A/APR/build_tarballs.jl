# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "APR"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dlcdn.apache.org//apr/apr-$(version).tar.gz", "48e9dbf45ae3fdc7b491259ffb6ccf7d63049ffacbc1c0977cced095e4c2d5a2"),
    DirectorySource("./bundled/"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/apr-*

# Add `usigned long long` as option for size of `size_t`, and `long long` for `ssize_t`.
atomic_patch -p1 ../patches/size_t_fmt_long_long.patch

# stop libtool from building gen_test_char for non-native host
atomic_patch -p1 ../patches/remove-libtool-compile-gen_test_char.patch

# compile it with host compiler manually
${HOSTCC} -Wall -O2 -DCROSS_COMPILE tools/gen_test_char.c -s -o tools/gen_test_char${exeext}

# CPPFLAGS trick and configure hints are from https://bz.apache.org/bugzilla/show_bug.cgi?id=50146
export CPPFLAGS="-DAPR_IOVEC_DEFINED"

# Need to rebuild configure script after applying `size_t` patch.
autoreconf -fiv

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-installbuilddir=$(mktemp -d) \
    --enable-shared=yes \
    --enable-static=no \
    --disable-libtool-lock \
    --disable-lfs \
    --disable-dso \
    --disable-ipv6 \
    ac_cv_file__dev_zero=no \
    ac_cv_func_setpgrp_void=no \
    apr_cv_tcp_nodelay_with_cork=no \
    cross_compiling=yes \
    apr_cv_process_shared_works=no \
    apr_cv_mutex_robust_shared=no

make -j${nproc}
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libapr-1", :libapr)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
