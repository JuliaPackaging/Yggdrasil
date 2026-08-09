# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# For `should_build_platform`, used to build Windows separately below.
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "nauty"
upstream_version = v"2.9.3"
version = v"2.9.3"

# Collection of sources required to build nauty
sources = [
    # The usual pallini.di.uniroma1.it has an expired certificate and is currently broken.
    # This loads the tarball from McKay's website. The file should be identical.
    ArchiveSource("https://users.cecs.anu.edu.au/~bdm/nauty/nauty$(upstream_version.major)_$(upstream_version.minor)_$(upstream_version.patch).tar.gz",
		  "9fc4edae04f88a0f5883985be3b39cf7f898fd6cc96e96b9ee25452743cc1b5b"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/nauty*

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib"

EXEEXT=""
EXTRA_TARGETS=(checks6 sumlines)
EXTRA_CONFIGURE_FLAGS=()
LIBDIR_FLAG="--libdir=${libdir}"

if [[ "${target}" == *-mingw* ]]; then
    EXEEXT=".exe"

    # sumlines needs two POSIX headers that Windows does not have.
    EXTRA_TARGETS=(checks6)

    # BinaryBuilder puts Windows DLLs in bin/, but libtool works out where to
    # install them by looking one level up from lib/. Give it lib/ so they land
    # in bin/ as intended.
    LIBDIR_FLAG="--libdir=${prefix}/lib"

    # On Windows a `long` is only 32 bits, so nauty would quietly pick 32-bit
    # words on a 64-bit build. Ask for 64.
    if [[ "${target}" == x86_64-* ]]; then
        EXTRA_CONFIGURE_FLAGS=(--enable-wordsize=64)
    fi

    # Without this, the Windows C library prints large numbers as garbage, and
    # nauty prints all of its counts that way.
    export CPPFLAGS="${CPPFLAGS} -D__USE_MINGW_ANSI_STDIO=1"

    # Windows gives a program far less stack than Unix does, and a few tools
    # (cubhamg especially) keep big arrays there and crash on startup without
    # this.
    export LDFLAGS="${LDFLAGS} -Wl,--stack,8388608"
fi

# We patched configure.ac, so configure has to be regenerated from it. Plain
# autoconf, not autoreconf: nauty ships a newer libtool than the build
# environment has, and autoreconf would replace it with the older one.
autoconf --force

# We use --enable-generic to ensure maximum hardware compatibility and we
# use --disable-popcnt to disable the `popcnt` CPU instruction on x86.
./configure --prefix=$prefix \
	    --build=${MACHTYPE} \
	    --host=${target} \
	    --enable-generic \
	    --enable-shared \
	    --disable-popcnt \
	    ${LIBDIR_FLAG} \
	    --bindir=${bindir} \
	    "${EXTRA_CONFIGURE_FLAGS[@]}"

make -j${nproc}

# In addition to the default install, we build thread-local-storage libraries and the programs checks6 and sumlines.
# These two programs were part of the default install in an older version of nauty and are included for compatibility.
make install TLSinstall "${EXTRA_TARGETS[@]}"

# The Windows compiler does not add .exe to what it builds, so take whichever
# name is there and install it under the name Windows needs.
for p in "${EXTRA_TARGETS[@]}"; do
    if [[ -f ${p}${EXEEXT} ]]; then
        cp ${p}${EXEEXT} ${bindir}/${p}${EXEEXT}
    else
        cp ${p} ${bindir}/${p}${EXEEXT}
    fi
done

install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# shortg needs fork(), pipe() and wait() and sumlines needs <pwd.h> and <glob.h>,
# so neither can be built for Windows. A single `build_tarballs` call has one
# fixed list of products, so Windows is built separately below.
platforms_windows = filter(Sys.iswindows, platforms)
platforms_rest = filter(!Sys.iswindows, platforms)

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
   ExecutableProduct("showg", :showg),
   ExecutableProduct("subdivideg", :subdivideg),
   ExecutableProduct("twohamg", :twohamg),
   ExecutableProduct("uniqg", :uniqg),
   ExecutableProduct("vcolg", :vcolg),
   ExecutableProduct("watercluster2", :watercluster2),

   # New tools added by nauty 2.9.
   ExecutableProduct("addptg", :addptg),
   ExecutableProduct("ancestorg", :ancestorg),
   ExecutableProduct("assembleg", :assembleg),
   ExecutableProduct("countneg", :countneg),
   ExecutableProduct("dimacs2g", :dimacs2g),
   ExecutableProduct("distgraphg", :distgraphg),
   ExecutableProduct("edgetransg", :edgetransg),
   ExecutableProduct("gengL", :gengL),
   ExecutableProduct("genktreeg", :genktreeg),
   ExecutableProduct("genposetg", :genposetg),
   ExecutableProduct("nbrhoodg", :nbrhoodg),
   ExecutableProduct("productg", :productg),
   ExecutableProduct("ransubg", :ransubg),
   ExecutableProduct("underlyingg", :underlyingg),
]

# Everything except Windows also gets the two tools that need POSIX facilities.
products_rest = [
    products;
    ExecutableProduct("shortg", :shortg);
    ExecutableProduct("sumlines", :sumlines);
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"), # for sumlines
]

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products, dependencies;
                   julia_compat="1.6",
                   preferred_gcc_version=v"6")
end
if any(should_build_platform.(triplet.(platforms_rest)))
    build_tarballs(ARGS, name, version, sources, script, platforms_rest, products_rest, dependencies;
                   julia_compat="1.6",
                   preferred_gcc_version=v"6")
end
