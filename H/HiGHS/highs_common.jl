# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.2.2"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "3f0a74587ff25009f12a73efcfbf5dd8aef45a4a",
    ),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

function build_script(; shared_libs::String)
    return "BUILD_SHARED=$(shared_libs)\n" * raw"""
cd $WORKSPACE/srcdir

mkdir -p HiGHS/build
cd HiGHS/build

# Do fully static build only on Windows
if [[ "${BUILD_SHARED}" == "OFF" ]] && [[ "${target}" == *-mingw* ]]; then
    export CXXFLAGS="-static"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=${BUILD_SHARED} \
    -DFAST_BUILD=ON \
    -DJULIA=ON \
    -DIPX=ON ..

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

install_license ../LICENSE

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
