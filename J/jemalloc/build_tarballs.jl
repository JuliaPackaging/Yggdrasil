# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jemalloc"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jemalloc/jemalloc.git", "a4e81221cceeb887708d53015d3d1f1f9642980a"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),    
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jemalloc/

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the error: 'value' is unavailable: introduced in macOS 10.14 issue
    export CXXFLAGS="-mmacosx-version-min=10.15"
    # ...and install a newer SDK which supports `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

autoconf

if [[ "${target}" == *-freebsd* ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls --with-jemalloc-prefix
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls --enable-cpuset
else
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-initial-exec-tls
fi

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libjemalloc", "jemalloc"], :libjemalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
