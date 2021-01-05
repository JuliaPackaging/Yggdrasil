# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

function configure(version; experimental::Bool=false)
    name = "LLVMLibUnwind"

    hash = Dict(
        v"11.0.0" => "8455011c33b14abfe57b2fd9803fb610316b16d4c9818bec552287e2ba68922f",
    )

    # Collection of sources required to complete build
    sources = [
        ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/libunwind-$(version).src.tar.xz",
                      hash[version])
    ]

    # Bash recipe for building across all platforms
    script = raw"""
cd $WORKSPACE/srcdir/libunwind*

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$prefix)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_DOCS=OFF)
CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_PEDANTIC=OFF)

if [[ ${target} == x86_64-w64-mingw32 ]]; then
    # Support for threading requires Windows Vista.
    export CXXFLAGS="-D_WIN32_WINNT=0x0600"
fi

mkdir build && cd build
cmake "${CMAKE_FLAGS[@]}" ..
make -j${nprocs}
make install

# Move over the DLL. TODO: There may be a CMAKE flag for this.
if [[ ${target} == *mingw32* ]]; then
    mkdir -p "${libdir}"
    mv -v lib/libunwind.dll "${libdir}"
fi
"""

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms(; experimental=experimental)

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libunwind", :libunwind),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = Dependency[
    ]

    return name, version, sources, script, platforms, products, dependencies
end
