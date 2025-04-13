# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xorriso"
version = v"1.5.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/gnu-mirror-unofficial/xorriso/raw/refs/heads/master/xorriso-$(version).tar.gz", "89a78b902ded443c3e4b31b3ba586ccbf06a447836d37f1082dfb1e429952217")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xorriso-*

# Platform-specific configuration
if [[ "${target}" == *-apple-* ]]; then
    export LDFLAGS="-L${libdir}"
    export LIBS="-liconv"
    export CPPFLAGS="-I${includedir}"
fi

./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} --disable-launch-frontend
make -j${nproc}

install_license COPYING
install -Dvm 755 "xorriso/xorriso${exeext}" "${bindir}/xorriso${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "freebsd"), 
    Platform("aarch64", "freebsd")
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("xorriso", :xorriso)
]

# Dependencies that must be installed before this package can be built
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Readline_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Libiconv_jll"),
    Dependency("acl_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Attr_jll", platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
