# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nauty"
upstream_version = v"2.8.9"
version = v"2.8.10"

# Collection of sources required to build nauty
sources = [
    ArchiveSource("https://pallini.di.uniroma1.it/nauty$(upstream_version.major)_$(upstream_version.minor)_$(upstream_version.patch).tar.gz",
		  "c97ab42bf48796a86a598bce3e9269047ca2b32c14fc23e07208a244fe52c4ee"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/nauty*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib"

# Nauty's configure script performs a runtime check to find out whether the
# `popcnt` CPU instruction is available. This check is not possible during cross-compilation,
# which causes the entire configure script to fail. We patch `configure.ac` to simply disable
# `popcnt` while cross-compiling, and generate a new, working configure script with `autoreconf`.
atomic_patch -p1 ../patches/autotools.patch
autoreconf -v

# We use --enable-generic to ensure maximum hardware compatibility and we
# use --disable-popcnt to disable the `popcnt` CPU instruction on x86.
./configure --prefix=$prefix \
	    --build=${MACHTYPE} \
	    --host=${target} \
	    --enable-generic \
	    --enable-shared \
	    --disable-popcnt \
	    --libdir=${libdir} \
	    --bindir=${bindir}

make -j${nproc}

# In addition to the default install, we build thread-local-storage libraries and the programs checks6 and sumlines.
# These two programs were part of the default install in an older version of nauty and are included for compatibility.
make install TLSinstall checks6 sumlines

cp checks6 ${bindir}
cp sumlines ${bindir}

install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
   LibraryProduct("libnauty", :libnauty),
   LibraryProduct("libnauty1", :libnauty1),
   LibraryProduct("libnautyL", :libnautyL),
   LibraryProduct("libnautyL1", :libnautyL1),
   LibraryProduct("libnautyS", :libnautyS),
   LibraryProduct("libnautyS1", :libnautyS1),
   LibraryProduct("libnautyW", :libnautyW),
   LibraryProduct("libnautyW1", :libnautyW1),
   LibraryProduct("libnautyT", :libnautyT),
   LibraryProduct("libnautyT1", :libnautyT1),
   LibraryProduct("libnautyTL", :libnautyTL),
   LibraryProduct("libnautyTL1", :libnautyTL1),
   LibraryProduct("libnautyTS", :libnautyTS),
   LibraryProduct("libnautyTS1", :libnautyTS1),
   LibraryProduct("libnautyTW", :libnautyTW),
   LibraryProduct("libnautyTW1", :libnautyTW1),

   ExecutableProduct("NRswitchg", :NRswitchg),
   ExecutableProduct("addedgeg", :addedgeg),
   ExecutableProduct("amtog", :amtog),
   ExecutableProduct("biplabg", :biplabg),
   # ExecutableProduct("blisstog", :blisstog), # The required source file (blisstog.c) is missing since at least nauty v2.8.8
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
   ExecutableProduct("uniqg", :uniqg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"), # for sumlines
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 1
