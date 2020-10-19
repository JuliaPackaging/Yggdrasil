# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "blis"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flame/blis.git", "68b88aca6692c75a9f686187e6c4a4e196ae60a9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd blis/

for i in ./config/*/*.mk; do

    # Building in container forbids -march options
    sed -i "s/-march[^ ]*//g" $i
    # Building in container forbids unsafe optimization.
    sed -i "s/-ffast-math//g" $i
    sed -i "s/-funsafe-math-optimizations//g" $i

done

case ${target} in

    *"x86_64"*"linux"*) 
        export BLI_CONFIG=x86_64
        export BLI_THREAD=openmp
        ;;
    *"x86_64"*"w64"*) 
        # MinGW doesn't support savexmm instructions
        # Build only for AMD processors.
        export BLI_CONFIG=amd64
        export BLI_THREAD=openmp
        ;;
    *"x86_64"*"apple"*) 
        export BLI_CONFIG=x86_64
        export BLI_THREAD=openmp
        export CC=gcc
        export CXX=g++
        ;;
    *"x86_64"*"freebsd"*) 
        export BLI_CONFIG=x86_64
        export BLI_THREAD=openmp
        export CC=gcc
        export CXX=g++
        ;;
    *"aarch64"*"linux"*) 
        # Aarch64 has no metaconfiguration support yet.
        # Use Cortex-A57 for the moment.
        export BLI_CONFIG=cortexa57
        export BLI_THREAD=openmp
        ;;
    *"arm"*"linux"*) 
        export BLI_CONFIG=cortexa9
        export BLI_THREAD=none
        ;;
    *)
        ;; 

esac

./configure -p ${prefix} -t ${BLI_THREAD} ${BLI_CONFIG}
make -j${nproc}
make install

# Rename .dll for Windows targets.
if [[ "${target}" == *"x86_64"*"w64"* ]]; then
    mkdir -p ${prefix}/bin
    mv ${prefix}/lib/libblis.3.dll ${prefix}/bin/libblis.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libblis", :blis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
