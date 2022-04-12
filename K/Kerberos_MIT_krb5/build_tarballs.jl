# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MIT_kerberos_krb5"
version = v"1.19.3"

# Collection of sources required to complete build
sources = [
ArchiveSource("https://kerberos.org/dist/krb5/1.19/krb5-1.19.3.tar.gz", "56d04863cfddc9d9eb7af17556e043e3537d41c6e545610778676cf551b9dcd0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd krb5-1.19.3/src
ac_cv_func_regcomp=yes ac_cv_printf_positional=yes krb5_cv_attr_constructor_destructor=yes,yes ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libgssapi_krb5", :libgssapi_krb5),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[ ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
