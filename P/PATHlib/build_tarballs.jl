using BinaryBuilder, Printf

name = "PATHlib"
version = v"4.7.3"

# I guess they're hoping for double-digit numbers of patch releases.  /shrug
version_str = @sprintf("%d.%d.%02d", version.major, version.minor, version.patch)

# Collection of sources required to build
sources = [
    "https://github.com/ampl/pathlib/archive/$(version_str).tar.gz" =>
    "93244121cb03d1c726fcb4e33aa86e8cd59864c873eb03733b07aaef7f448ed8",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/

mkdir -p ${prefix}/include ${prefix}/lib ${libdir}

function target_libdir()
{
    if [[ ${target} == x86_64-linux-gnu ]]; then
        echo -n linux64
    elif [[ ${target} == i686-linux-gnu ]]; then
        echo -n linux32
    elif [[ ${target} == x86_64-apple-* ]]; then
        echo -n osx
    elif [[ ${target} == x86_64-w64-* ]]; then
        echo -n win64
    elif [[ ${target} == i686-w64-* ]]; then
        echo -n win32
    else
        echo "ERROR: We don't have an upstream PATHlib release for ${target}" >&2
        exit 1
    fi
}

# pathlib comes as precompiled binaries, so we just copy the binaries and the include directory over
# We move the `dlext` stuff first as that sometimes goes into `bin`, and everything else into `lib`
mv -v pathlib-*/lib/$(target_libdir)/*.${dlext} ${libdir}
mv -v pathlib-*/lib/$(target_libdir)/* ${prefix}/lib
mv -v pathlib-*/include/*.h ${prefix}/include

# Add linkage args
LDFLAGS="${LDFLAGS} -lm -lgfortran"
LIBNAME="libpath47julia.${dlext}"

# By linking against the static libpath library, we are able to 
LIBPATH_A="libpath47.a"
if [[ ${target} == *mingw* ]]; then
    LIBPATH_A="path47.lib"
fi

# Add compiler flags, some platform-dependent
CFLAGS="${CFLAGS} -I${prefix}/include -fPIC -shared"
if [[ ${target} == *linux* ]]; then
    CFLAGS="${CFLAGS} -Wl,-soname,${LIBNAME}"
elif [[ ${target} == *mingw* ]]; then
    CFLAGS="${CFLAGS} -DFNAME_LCASE_NODECOR -DUSE_OUTPUT_INTERFACE"
fi

cc -o ${libdir}/${LIBNAME} pathjulia.c ${prefix}/lib/${LIBPATH_A} ${CFLAGS} ${LDFLAGS} 

# Install license file
install_license pathlib-*/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    Linux(:i686; libc=:glibc),
    MacOS(),
    Windows(:x86_64),
    Windows(:i686),
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpath47julia", :libpath47julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

