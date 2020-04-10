# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcxxwrap_julia"
version = v"0.7.0"

const is_yggdrasil = haskey(ENV, "BUILD_BUILDNUMBER")
git_repo = is_yggdrasil ? "https://github.com/JuliaInterop/libcxxwrap-julia.git" : joinpath(ENV["HOME"], "src/julia/libcxxwrap-julia/")
unpack_target = is_yggdrasil ? "" : "libcxxwrap-julia"

# Collection of sources required to complete build
sources = [
    GitSource(git_repo, "7959f09947f95e67ee094a2ee3fb8b7f9be696f8", unpack_target=unpack_target),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/armv7l/1.3/julia-1.3.1-linux-armv7l.tar.gz", "965c8fab2214f8ce1b3d449d088561a6de61be42543b48c3bbadaed5b02bf824"; unpack_target="julia-arm-linux-gnueabihf"),
    ArchiveSource("https://julialang-s3.julialang.org/bin/linux/x64/1.3/julia-1.3.1-linux-x86_64.tar.gz", "faa707c8343780a6fe5eaf13490355e8190acf8e2c189b9e7ecbddb0fa2643ad"; unpack_target="julia-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-apple-darwin14.tar.gz", "f2e5359f03314656c06e2a0a28a497f62e78f027dbe7f5155a5710b4914439b1"; unpack_target="julia-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/Gnimuc/JuliaBuilder/releases/download/v1.3.0/julia-1.3.0-x86_64-w64-mingw32.tar.gz", "c7b2db68156150d0e882e98e39269301d7bf56660f4fc2e38ed2734a7a8d1551"; unpack_target="julia-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""

case "$target" in
	arm-linux-gnueabihf|x86_64-linux-gnu)
        Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/julia-1.3.1
        ;;
    x86_64-apple-darwin14|x86_64-w64-mingw32)
        Julia_PREFIX=${WORKSPACE}/srcdir/julia-$target/juliabin
        ;;
esac

mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ../libcxxwrap-julia/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/libcxxwrap-julia*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:x86_64),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcxxwrap_julia", :libcxxwrap_julia; dlopen_flags=[:RTLD_GLOBAL]),
    LibraryProduct("libcxxwrap_julia_stl", :libcxxwrap_julia_stl; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
