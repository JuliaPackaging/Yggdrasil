# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "satsuma"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/markusa4/satsuma", "be6beeb6d2538aa133b1f6b7cad84655cda950bb"),
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

cd $WORKSPACE/srcdir/satsuma

for f in $WORKSPACE/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cp $WORKSPACE/srcdir/tsl/* tsl/

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release

make -C build satsuma
install -Dvm 755 build/satsuma -t "${bindir}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows) |> expand_cxxstring_abis
# The products that we will ensure are always built
products = [
    ExecutableProduct("satsuma", :satsuma)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"13")
