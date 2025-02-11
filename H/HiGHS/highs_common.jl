# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.9.0"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "66f735e60ce4d4835edaa05a35f2bd4048969c54",
    ),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable riscv for now
platforms = filter!(p -> arch(p) != "riscv64", platforms)

function build_script(; shared_libs::String)
    build_static = shared_libs == "OFF" ? "ON" : "OFF"
    return "BUILD_SHARED=$(shared_libs)\nBUILD_STATIC=$(build_static)\n" * raw"""
cd $WORKSPACE/srcdir/HiGHS

# Remove system CMake to use the jll version
apk del cmake

mkdir -p build
cd build

# Do fully static build only on Windows
if [[ "${BUILD_SHARED}" == "OFF" ]] && [[ "${target}" == *-mingw* ]]; then
    export CXXFLAGS="-static"
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=${BUILD_SHARED} \
    -DZLIB_USE_STATIC_LIBS=${BUILD_STATIC} \
    -DFAST_BUILD=ON ..

if [[ "${target}" == *-linux-* ]]; then
        make -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build . --config Release
    else
        cmake --build . --config Release --parallel
    fi
fi
make install

install_license ../LICENSE.txt

if [[ "${BUILD_SHARED}" == "OFF" ]]; then
    # Delete the static library to save space
    rm -r ${prefix}/lib
    if [[ "${target}" == *-mingw* ]]; then
        # The Windows build ships also GCC runtime, add its license as well
        install_license /usr/share/licenses/GPL-3.0+
    fi
fi
"""
end
