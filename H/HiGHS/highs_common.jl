# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.2.0"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "7a3f716bb2ad2df67525db8414ae48f5226dedd6",
    ),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

function build_script(; shared_libs::String)
    return "BUILD_SHARED=$(shared_libs)\n" * raw"""
cd $WORKSPACE/srcdir
if [[ "${target}" == *86*-linux-musl* ]]; then
    pushd /opt/${target}/lib/gcc/${target}/*/include
    # Fix bug in Musl C library, see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    atomic_patch -p0 $WORKSPACE/srcdir/patches/mm_malloc.patch
    popd
fi
mkdir -p HiGHS/build
cd HiGHS/build

if [[ "${BUILD_SHARED}" == "OFF" ]]; then
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
    if [[ "${target}" == *-gnu ]] || [[ "${target}" == *-mingw* ]]; then
        # In these cases we're shipping also GCC runtime, add its license as well
        install_license install_license /usr/share/licenses/GPL3
    fi
fi
"""
end
