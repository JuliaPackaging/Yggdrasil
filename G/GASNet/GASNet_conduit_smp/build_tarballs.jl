using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "../common.jl"))

name = gasnet_conduit_name("smp")

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/GASNet-2024.5.0/

# TODO this needs platform-dependent optimization! should be automatically detected on target platforms
## Whether the system has a working version of anonymous mmap
export CROSS_HAVE_MMAP='1'

## The system VM page size (ie mmap granularity, even if swapping is not supported)
export CROSS_PAGESIZE=4096

## Does the system stack grow up?
export CROSS_STACK_GROWS_UP='0'

## MIC doesn't have cmpxchg16b instruction!
export CROSS_HAVE_X86_CMPXCHG16B='0'

## Enable Posix shared memory
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

make install-includeHEADERS

install_license license.txt
"""

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgasnet-smp-seq", :libgasnet_smp_seq),
    LibraryProduct("libgasnet-smp-par", :libgasnet_smp_par),
    LibraryProduct("libgasnet-smp-parsync", :libgasnet_smp_parsync),
    FileProduct("include/gasnet.h", :gasnet_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7", julia_compat="1.6", lazy_artifacts=true)
