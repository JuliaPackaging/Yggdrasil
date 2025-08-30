using BinaryBuilder

name = "QD"
version = v"2.3.24"

# Collection of sources required to build SDPA-QD
sources = [
    ArchiveSource("https://www.davidhbailey.com/dhbsoftware/qd-$(version).tar.gz",
                  "a47b6c73f86e6421e86a883568dd08e299b20e36c11a99bdfbe50e01bde60e38"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qd*

#TODO ./update_configure_scripts
#TODO 
#TODO if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == powerpc64le-* ]]; then
#TODO     # Regenerate the configure to be able to build the shared libraries
#TODO     autoreconf -vi
#TODO fi

./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --prefix=${prefix} \
    --disable-fma \
    --disable-static \
    --enable-shared
make -j${nproc} #TODO module_ext=mod
make install #TODO module_ext=mod

install_license BSD-LBNL-License.doc

#TODO if [[ "${target}" == *-ming* ]]; then
#TODO     # We have to manually build all shared libraries for Windows one by one
#TODO     cd "${prefix}/lib"
#TODO     ar x libqd.a
#TODO     c++ -shared -o "${libdir}/libqd.${dlext}" *.o
#TODO     rm *.o
#TODO     ar x libqdmod.a
#TODO     c++ -shared -o "${libdir}/libqdmod.${dlext}" *.o "${libdir}/libqd.${dlext}" -lgfortran
#TODO     rm *.o
#TODO fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#TODO platforms = expand_cxxstring_abis(filter!(!Sys.iswindows, supported_platforms()))
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqd_f_main", :libqd_f_main),
    LibraryProduct("libqdmod", :libqdmod, dont_dlopen = true),
    LibraryProduct("libqd", :libqd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
