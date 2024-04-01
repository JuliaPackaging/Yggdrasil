# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libjlnode"
version = v"18.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/sunoru/jlnode/archive/refs/tags/v$version.tar.gz", "82991ee31522e89179dd0f9c1b43a0d9f5c5f28932440f32e8580f2d28ce5fda"),
    ArchiveSource("https://github.com/nodejs/node-addon-api/archive/refs/tags/v5.0.0.tar.gz", "2bdf9c540f67c43036d58b3146e61b437148939efc8d4cde2d1314fdaeb39e9b"),
    ArchiveSource(
        "https://github.com/sunoru/jlnode/releases/download/v$(version)/Windows-dist.zip",
        "072ee1ea8df849e24581a2a016a425fedd1b33d7e4d6336ff566629c2798ae8e",
        unpack_target = "x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://github.com/sunoru/jlnode/releases/download/v$(version)/macOS-dist.zip",
        "fb2c809aef9941bf2a113a5a897589257d6f90514a17d304aad922c03672614d",
        unpack_target = "x86_64-apple-darwin14"
    ),
]

w64_script = raw"""
cd ${target}/*-dist
mkdir -p ${bindir}
mv lib/*.dll ${bindir}/
mv lib ${prefix}/
cd ../../jlnode-*
install_license ./LICENSE.md
"""

mac_script = raw"""
cd ${target}/*-dist
mv lib/* ${prefix}/lib/
cd ../../jlnode-*
install_license ./LICENSE.md
"""

linux_script = raw"""
cd node-addon-api-*
export NAPI_INC=`pwd`

cd ../jlnode-*
mkdir build
cd build
cmake .. -G"Unix Makefiles" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="`pwd`/Release" \
    -DCMAKE_JS_INC="${prefix}/include/node" \
    -DNAPI_INC="$NAPI_INC" \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build .
cmake --install .
install_license ../LICENSE.md
"""

script = """
cd \$WORKSPACE/srcdir
if [[ \$target == *w64* ]]
then
    $w64_script
elif [[ \$target == *apple* ]]
then
    $mac_script
elif [[ \$target == *linux* ]]
then
    $linux_script
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),

    Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),

    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libjlnode", :libjlnode),
    FileProduct("lib/jlnode_addon.node", :jlnode_addon)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libnode_jll", v"18.12.1", compat="18")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"6"
)
