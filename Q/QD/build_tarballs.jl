using BinaryBuilder

name = "QD"
version = v"2.3.22"

# Collection of sources required to build SDPA-QD
sources = [
    ArchiveSource("https://www.davidhbailey.com/dhbsoftware/qd-2.3.22.tar.gz",
                  "30c1ffe46b95a0e9fa91085949ee5fca85f97ff7b41cd5fe79f79bab730206d3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qd-2.3.22
update_configure_scripts

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == powerpc64le-* ]]; then
    # Regenerate the configure to be able to build the shared libraries
    autoreconf -vi
fi

./configure --enable-shared --enable-fast-install=no --disable-fma --prefix=$prefix --host=$target --build=${MACHTYPE}
make -j${nproc} module_ext=mod
make install module_ext=mod

install_license BSD-LBNL-License.doc

if [[ "${target}" == *-ming* ]]; then
    # We have to manually build all shared libraries for Windows one by one
    cd "${prefix}/lib"
    ar x libqd.a
    c++ -shared -o "${libdir}/libqd.${dlext}" *.o
    rm *.o
    ar x libqdmod.a
    c++ -shared -o "${libdir}/libqdmod.${dlext}" *.o "${libdir}/libqd.${dlext}" -lgfortran
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(p -> !isa(p, Windows), supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libqd_f_main", :libqd_f_main),
    LibraryProduct("libqdmod", :libqdmod, dont_dlopen = true),
    LibraryProduct("libqd", :libqd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
