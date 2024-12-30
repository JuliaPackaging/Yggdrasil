using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "RAxML"
version = v"8.2.13"
raxml_version = v"8.2.12"
hash = "a33ff40640b4a76abd5ea3a9e2f57b7dd8d854f6"
sources = [
    GitSource("https://github.com/stamatak/standard-RAxML.git", hash),
]

script = raw"""
cd ${WORKSPACE}/srcdir/standard-RAxML

# see section IV in manual for license spec 
# https://github.com/stamatak/standard-RAxML/blob/master/manual/NewManual.pdf
install_license /usr/share/licenses/GPL-3.0+

# Sequential
make -f Makefile.gcc -j${nproc}
rm *.o
make -f Makefile.SSE3.gcc -j${nproc}
rm *.o
make -f Makefile.AVX.gcc -j${nproc}
rm *.o

# PTHREADS
make -f Makefile.PTHREADS.gcc -j${nproc}
rm *.o
make -f Makefile.SSE3.PTHREADS.gcc -j${nproc}
rm *.o
make -f Makefile.AVX.PTHREADS.gcc -j${nproc}
rm *.o

# MPI version
if [[ "$target" == *-mingw* ]]; then
    GLOBAL_DEPS="axml.h globalVariables.h rmq.h rmqs.h ${includedir}/mpi.h"
    LIBRARIES="-lm -lmsmpi -I${includedir} -L${libdir}"
    
    CFLAGS="-D_WAYNE_MPI -D_GNU_SOURCE -fomit-frame-pointer -funroll-loops -O2 -msse -I${includedir} -L${libdir} -lmsmpi"
    make -f Makefile.MPI.gcc -j${nproc} \
        CC=${target}-gcc \
        CFLAGS="$CFLAGS" \
        GLOBAL_DEPS="${GLOBAL_DEPS}" \
        LIBRARIES="${LIBRARIES}"
    rm *.o
    
    CFLAGS="-D_WAYNE_MPI -D__SIM_SSE3 -O2 -D_GNU_SOURCE -msse3 -fomit-frame-pointer -funroll-loops -I${includedir} -L${libdir} -lmsmpi"
    make -f Makefile.SSE3.MPI.gcc -j${nproc} \
        CC=${target}-gcc \
        CFLAGS="$CFLAGS" \
        GLOBAL_DEPS="${GLOBAL_DEPS}" \
        LIBRARIES="${LIBRARIES}"
    rm *.o

    CFLAGS="-D_WAYNE_MPI -D__SIM_SSE3 -D__AVX -O2 -D_GNU_SOURCE -msse3 -fomit-frame-pointer -funroll-loops -I${includedir} -L${libdir} -lmsmpi"
    make -f Makefile.AVX.MPI.gcc -j${nproc} \
        CC=${target}-gcc \
        CFLAGS="$CFLAGS" \
        GLOBAL_DEPS="${GLOBAL_DEPS}" \
        LIBRARIES="${LIBRARIES}"
    rm *.o
else
    make -f Makefile.MPI.gcc -j${nproc}
    rm *.o
    make -f Makefile.SSE3.MPI.gcc -j${nproc}
    rm *.o
    make -f Makefile.AVX.MPI.gcc -j${nproc}
    rm *.o
fi

for f in raxmlHPC*; do 
    install -Dvm 755 $f ${bindir}/${f}${exeext}; 
done
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# currently RAxML assumes intel cpus with at least SSE instructions
platforms = filter(p -> BinaryBuilder.proc_family(p) == "intel", supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
filter!(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
filter!(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

products = [
    ExecutableProduct("raxmlHPC", :raxmlHPC),
    ExecutableProduct("raxmlHPC-SSE3", :raxmlHPC_SSE3),
    ExecutableProduct("raxmlHPC-AVX", :raxmlHPC_AVX),
    ExecutableProduct("raxmlHPC-PTHREADS", :raxmlHPC_PTHREADS),
    ExecutableProduct("raxmlHPC-PTHREADS-SSE3", :raxmlHPC_PTHREADS_SSE3),
    ExecutableProduct("raxmlHPC-PTHREADS-AVX", :raxmlHPC_PTHREADS_AVX),
    ExecutableProduct("raxmlHPC-MPI", :raxmlHPC_MPI),
    ExecutableProduct("raxmlHPC-MPI-SSE3", :raxmlHPC_MPI_SSE3),
    ExecutableProduct("raxmlHPC-MPI-AVX", :raxmlHPC_MPI_AVX),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
