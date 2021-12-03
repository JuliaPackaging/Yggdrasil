# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TOPCOM"
version = v"0.17.8"
underscored = join([version.major,version.minor,version.patch],"_")

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.wm.uni-bayreuth.de/de/team/rambau_joerg/TOPCOM-Downloads/TOPCOM-$(underscored).tgz",
                  "3f83b98f51ee859ec321bacabf7b172c25884f14848ab6c628326b987bd8aaab"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/topcom-*
for f in ../patches/*.patch; do
    atomic_patch -p1 ${f}
done
if [[ $target == *mingw* ]]; then
    # unfortunately we cannot used shared libraries on windows because of circular dependencies
    # until this improves the following extra ldflag is not needed
    # sed -i '/_la_LDFLAGS/ s/$/ -no-undefined/g' lib-src/Makefile.am lib-src-reg/Makefile.am
    libopts="--enable-static --disable-shared"
else
    libopts="--enable-shared --disable-static"
fi
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} CPPFLAGS="-I${includedir}/cddlib -I${includedir}" $libopts
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
platforms_win = filter(Sys.iswindows, platforms)
platforms_unix = filter(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products_win = [
    ExecutableProduct("chiro2allfinetriangs", :chiro2allfinetriangs),
    ExecutableProduct("chiro2ntriangs", :chiro2ntriangs),
    ExecutableProduct("points2nflips", :points2nflips),
    ExecutableProduct("chiro2mintriang", :chiro2mintriang),
    ExecutableProduct("points2facets", :points2facets),
    ExecutableProduct("chiro2cocircuits", :chiro2cocircuits),
    ExecutableProduct("chiro2placingtriang", :chiro2placingtriang),
    ExecutableProduct("points2finetriangs", :points2finetriangs),
    ExecutableProduct("cocircuits2facets", :cocircuits2facets),
    ExecutableProduct("chiro2alltriangs", :chiro2alltriangs),
    ExecutableProduct("points2nallfinetriangs", :points2nallfinetriangs),
    ExecutableProduct("chiro2finetriangs", :chiro2finetriangs),
    ExecutableProduct("points2ntriangs", :points2ntriangs),
    ExecutableProduct("points2placingtriang", :points2placingtriang),
    ExecutableProduct("chiro2dual", :chiro2dual),
    ExecutableProduct("points2flips", :points2flips),
    ExecutableProduct("santos_dim4_triang", :santos_dim4_triang),
    ExecutableProduct("chiro2nalltriangs", :chiro2nalltriangs),
    ExecutableProduct("points2volume", :points2volume),
    ExecutableProduct("points2finetriang", :points2finetriang),
    ExecutableProduct("chiro2circuits", :chiro2circuits),
    ExecutableProduct("points2allfinetriangs", :points2allfinetriangs),
    ExecutableProduct("points2nalltriangs", :points2nalltriangs),
    ExecutableProduct("santos_22_triang", :santos_22_triang),
    ExecutableProduct("points2nfinetriangs", :points2nfinetriangs),
    ExecutableProduct("chiro2nallfinetriangs", :chiro2nallfinetriangs),
    ExecutableProduct("chiro2nfinetriangs", :chiro2nfinetriangs),
    ExecutableProduct("chiro2finetriang", :chiro2finetriang),
    ExecutableProduct("chiro2triangs", :chiro2triangs),
    ExecutableProduct("points2alltriangs", :points2alltriangs),
    ExecutableProduct("points2chiro", :points2chiro),
    ExecutableProduct("points2triangs", :points2triangs),
    ExecutableProduct("santos_triang", :santos_triang)
]

products_unix = [
    LibraryProduct("libTOPCOM", :libTOPCOM),
    LibraryProduct("libCHECKREG", :libCHECKREG),
    products_win...
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll")
    Dependency("cddlib_jll")
]

include("../../fancy_toys.jl")

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_unix)))
    build_tarballs(ARGS, name, version, sources, script, platforms_unix, products_unix, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products_win, dependencies; julia_compat="1.6")
end
