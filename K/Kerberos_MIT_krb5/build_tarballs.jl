# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kerberos_MIT_krb5"
version = v"1.19.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://kerberos.org/dist/krb5/$(version.major).$(version.minor)/krb5-$(version).tar.gz",
                  "56d04863cfddc9d9eb7af17556e043e3537d41c6e545610778676cf551b9dcd0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/krb5-1.19.3/src
ac_cv_func_regcomp=yes ac_cv_printf_positional=yes krb5_cv_attr_constructor_destructor=yes,yes ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libgssapi_krb5", :libgssapi_krb5),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[ ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
