using BinaryBuilder

name = "TetGen"
version = v"1.6.0"

#
# Artifact builder for TetGen (c) Hang Si, see project home page https://tetgen.org
# TetGen's license is AGPLv3.
#
# TetGen source is C++ code, interfacing to Julia works via C wrapper by Simon Danisch
# in the cwrapper subdirectory.
#

sources = [
    ArchiveSource("https://wias-berlin.de/software/tetgen/1.5/src/tetgen1.6.0.zip",
                  "e7bbbb4fb8f47f0adc3b46b26ab172557ebb90808c06e21b902b2166717af582"),
    DirectorySource("cwrapper", target="cwrapper"),
]

script = raw"""
mkdir -p ${libdir}

cd $WORKSPACE/srcdir/tetgen1.6.0

#
# Patch tetgen.h with operators delegating new/delete to malloc/free for C/Julia compatibility.
#
mv tetgen.h tmp.h
sed -e "s/class tetgenio {/class tetgenio { void * operator new(size_t n) {  return malloc(n);} void operator delete(void* p) noexcept {free(p);} /g" tmp.h > tetgen.h

#
# Fix crash of README example (see TetGen.jl#26)
#
mv tetgen.cxx tmp.cxx
sed -e "s/tetrahedrons->items \* 10/(tetrahedrons->items + 100) * 10/g" tmp.cxx > tetgen.cxx

${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY -I. ${WORKSPACE}/srcdir/cwrapper/cwrapper.cxx -o cwrapper.o
${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY tetgen.cxx -o tetgen.o
${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY predicates.cxx -o predicates.o
# Compile and link together with C wrapper
EXTRA_LDFLAGS=()
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    # Avoid the 32-bit runtime pseudo-relocation into libstdc++-6.dll that aborts at load.
    EXTRA_LDFLAGS+=(-static-libstdc++ -static-libgcc)
fi
${CXX} $LDFLAGS "${EXTRA_LDFLAGS[@]}" -shared -fPIC tetgen.o predicates.o cwrapper.o -o ${libdir}/libtet.${dlext}

install -Dm644 tetgen.h ${includedir}/tetgen.h

install_license $WORKSPACE/srcdir/cwrapper/LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libtet", :libtet)
]
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
