# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "kdb_c_api"
version = v"2022.7.19"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KxSystems/kdb.git", "01fb1243c6b32079938ef88a4434e46d2f3c00be")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir
install_license kdb/LICENSE
mkdir ${libdir}
if [[ ${target} == aarch64-linux-* ]]; then opath="kdb/l64arm/c.o"; fi
if [[ ${target} == x86_64-linux-* ]]; then opath="kdb/l64/c.o"; fi
if [[ ${target} == i686-linux-* ]]; then opath="kdb/l32/c.o"; fi
if [[ ${target} == aarch64-apple-* ]]; then opath="kdb/m64/c.o"; fi
if [[ ${target} == x86_64-apple-* ]]; then opath="kdb/m64/c.o"; fi
if [[ ${target} == i686-apple-* ]]; then opath="kdb/m32/c.o"; fi
if [[ ${target} == x86_64-w64-* ]]; then opath="kdb/w64/c.dll"; fi
if [[ ${target} == i686-w64-* ]]; then opath="kdb/w32/c.dll"; fi
${CC} -shared -fPIC ${opath} -o ${libdir}/c.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"; ),
    Platform("i686", "windows"; ),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "windows"; ),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("c", :kdb_c_so)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
