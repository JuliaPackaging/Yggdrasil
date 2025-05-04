using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "../common.jl"))

name = gasnet_name("smp")
version = v"2024.5.0"

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/GASNet-2024.5.0/

# TODO this needs platform-dependent optimization!
export CROSS_HAVE_MMAP='1'
export CROSS_PAGESIZE=4096
export CROSS_STACK_GROWS_UP='0'
export CROSS_HAVE_X86_CMPXCHG16B='0'
export CROSS_HAVE_SHM_OPEN='1'

# if target contains apple-darwin, set RANLIB to ar (llvm-ranlib fails)
if [[ ${target} == *apple-darwin* ]]; then
    export RANLIB=ar
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${MACHTYPE} --target=${target} \
    --enable-cross-compile \
    --with-cflags=-fPIC --with-cxxflags=-fPIC --with-mpi-cflags=-fPIC \
    --enable-smp \
    --disable-udp \
    --disable-mpi

make -j${nproc}

# build for smp conduit
pushd smp-conduit
for file in libgasnet-smp-*.a; do
    # extract the object files from the static library
    ar -x $file

    # extract the suffix from the filename
    mode=${file#libgasnet-smp-}
    mode=${mode%.a}

    ${CC} -shared *.o -o libgasnet-smp-$mode.${dlext}
    install -Dvm 0755 libgasnet-smp-$mode.${dlext} ${libdir}/libgasnet-smp-$mode.${dlext}

    rm *.o
done
popd

install_license license.txt
"""

platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="gnu"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgasnet-smp-seq", :libgasnet_smp_seq),
    LibraryProduct("libgasnet-smp-par", :libgasnet_smp_par),
    LibraryProduct("libgasnet-smp-parsync", :libgasnet_smp_parsync),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7", julia_compat="1.6")
