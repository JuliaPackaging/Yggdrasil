# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nauty"
version = v"2.6.12" # Make sure to adjust version in the script down below, too!

# Collection of sources required to build 4ti2
sources = [
    ArchiveSource("http://pallini.di.uniroma1.it/nauty$(version.major)$(version.minor)r$(version.patch).tar.gz",
                  "862ae0dc3656db34ede6fafdb0999f7b875b14c7ab4fedbb3da4f28291eb95dc"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/nauty*

# Remove misleading libtool files 
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
rm -f /opt/${MACHTYPE}/${MACHTYPE}/lib*/*.la

# Patch based on one from Debian: add autotools build system which creates a
# shared library; compared to the Debian version, a bunch of things we don't
# need have been removed (perhaps even more should be removed?)
sed -e "s/@INJECTVER@/2.6.12/" < ../patches/autotoolization.patch > ../patches/autotoolization2.patch
atomic_patch -p1 ../patches/autotoolization2.patch

rm -f makefile*
mkdir -p m4
autoreconf -vi

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib"

./configure \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=$target \
    --enable-shared \
    --disable-static

make -j${nproc}
make install

install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
   LibraryProduct("libnauty", :libnauty),
   LibraryProduct("libnautyA1", :libnautyA1),
   LibraryProduct("libnautyL0", :libnautyL0),
   LibraryProduct("libnautyL1", :libnautyL1),
   LibraryProduct("libnautyS0", :libnautyS0),
   LibraryProduct("libnautyS1", :libnautyS1),
   LibraryProduct("libnautyW0", :libnautyW0),
   LibraryProduct("libnautyW1", :libnautyW1),

   ExecutableProduct("NRswitchg", :NRswitchg),
   ExecutableProduct("addedgeg", :addedgeg),
   ExecutableProduct("amtog", :amtog),
   ExecutableProduct("biplabg", :biplabg),
   ExecutableProduct("blisstog", :blisstog),
   ExecutableProduct("catg", :catg),
   ExecutableProduct("checks6", :checks6),
   ExecutableProduct("complg", :complg),
   ExecutableProduct("converseg", :converseg),
   ExecutableProduct("copyg", :copyg),
   ExecutableProduct("countg", :countg),
   ExecutableProduct("cubhamg", :cubhamg),
   ExecutableProduct("deledgeg", :deledgeg),
   ExecutableProduct("delptg", :delptg),
   ExecutableProduct("directg", :directg),
   ExecutableProduct("dreadnaut", :dreadnaut),
   ExecutableProduct("dretodot", :dretodot),
   ExecutableProduct("dretog", :dretog),
   ExecutableProduct("genbg", :genbg),
   ExecutableProduct("genbgL", :genbgL),
   ExecutableProduct("geng", :geng),
   ExecutableProduct("genquarticg", :genquarticg),
   ExecutableProduct("genrang", :genrang),
   ExecutableProduct("genspecialg", :genspecialg),
   ExecutableProduct("gentourng", :gentourng),
   ExecutableProduct("gentreeg", :gentreeg),
   ExecutableProduct("hamheuristic", :hamheuristic),
   ExecutableProduct("labelg", :labelg),
   ExecutableProduct("linegraphg", :linegraphg),
   ExecutableProduct("listg", :listg),
   ExecutableProduct("multig", :multig),
   ExecutableProduct("newedgeg", :newedgeg),
   ExecutableProduct("pickg", :pickg),
   ExecutableProduct("planarg", :planarg),
   ExecutableProduct("ranlabg", :ranlabg),
   ExecutableProduct("shortg", :shortg),
   ExecutableProduct("showg", :showg),
   ExecutableProduct("subdivideg", :subdivideg),
   ExecutableProduct("sumlines", :sumlines),
   ExecutableProduct("twohamg", :twohamg),
   ExecutableProduct("vcolg", :vcolg),
   ExecutableProduct("watercluster2", :watercluster2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"), # for sumlines
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

