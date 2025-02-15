# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kerberos_krb5"
version = v"1.21.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://web.mit.edu/kerberos/dist/krb5/$(version.major).$(version.minor)/krb5-$(version).tar.gz",
                  "b7a4cd5ead67fb08b980b21abd150ff7217e85ea320c9ed0c6dadd304840ad35"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/krb5*/src
ac_cv_func_regcomp=yes ac_cv_printf_positional=yes krb5_cv_attr_constructor_destructor=yes,yes ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
supported_platforms(; exclude=p -> !Sys.islinux(p) && !Sys.isfreebsd(p))

# The products that we will ensure are always built
products = [
    LibraryProduct("libgssapi_krb5", :libgssapi_krb5),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[ ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
