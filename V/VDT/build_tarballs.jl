# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "VDT"
version = v"0.4.6"

vdtgithash = Dict(v"0.4.6" => "fc894d2ac53426bd8cac14f1e685e1ce8630ffff")

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/dpiparo/vdt.git", vdtgithash[version])
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/vdt

install_license Licence.txt

CMAKE_OPTS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)

if [[ "$target" != x86_64-* ]]; then
  CMAKE_OPTS+=(-DSSE=OFF)
fi

cmake -GNinja "${CMAKE_OPTS[@]}" -B build -S .
cmake --build build
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libvdt", :libvdt)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
