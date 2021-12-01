# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MagicVLSI"
version = v"8.3.160"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Keno/magic.git", "8ab1743be8f6e0d7ab95e0c2e86688379fca1aad")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/magic/
apk add tcsh
apk add tcl
update_configure_scripts
cd scripts
autoreconf
cd ..
./configure --with-wish=wish8.6 --prefix=${prefix} --build=${MACHTYPE} --host=${target} LDFLAGS="-Wl,-rpath-link=/opt/${target}/${target}/lib64"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> (Sys.islinux(p) && libc(p) != "musl") || Sys.isfreebsd(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("tclmagic", :tclmagic, "lib/magic/tcl")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Tcl_jll", uuid="9fc9b8dd-f768-5d0d-bb0b-e65961e00eb6"))
    Dependency(PackageSpec(name="GLU_jll", uuid="bd17208b-e95e-5925-bf81-e2f59b3e5c61"))
    Dependency(PackageSpec(name="Cairo_jll"))
    Dependency(PackageSpec(name="Tk_jll"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
