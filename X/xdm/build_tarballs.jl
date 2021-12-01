# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xdm"
version = v"2.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xyce/xdm.git", "c87548b0bdd4d696ea103008d452082907951fc3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xdm
mv $prefix/lib/libboost_python.$dlext /workspace/destdir/lib/libboost_python38.$dlext || true
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBoost_NO_BOOST_CMAKE=ON
make -j$nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("SpiritExprCommon", :SpiritExprCommon, "xdm_bundle"),
    LibraryProduct("XdmRapidXmlReader", :XdmRapidXmlReader, "xdm_bundle"),
    LibraryProduct("SpiritCommon", :SpiritCommon, "xdm_bundle")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boostpython_jll", uuid="398de629-0a17-50a6-9837-8b3a70a53854"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
