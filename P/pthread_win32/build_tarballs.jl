# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pthread_win32"
version = v"3.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GerHobbelt/pthread-win32.git", "512a38decec4d2007d4b336f5f24f7e4afa23bd0")
]

dependencies = [
]

# Bash recipe for building across all platforms
script = raw"""
cd pthread-win32
apk add binutils
autoheader
autoconf
echo ${target}
if [[ "${target}" == *x86_64-w64-mingw32* ]]; then
    ./configure --host=x86-w64-mingw32
elif [[ "${target}" == *i686-w64-mingw32* ]]; then
    ./configure --host=i686-w64-mingw32
fi
make realclean
make GC
make install DLLDEST=${libdir} LIBDEST=${libdir} HDRDEST=${includedir}
#mkdir -p {bindir}/bin
#cp pthreadGC3.dll ${bindir}/pthread.dll
install_license /usr/share/licenses/APL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.iswindows(p), supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct("pthread", :pthread)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
