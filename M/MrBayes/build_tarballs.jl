using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "MrBayes"
version = v"3.2.8"
mrbayes_version = v"3.2.7"
sources = [
    GitSource("https://github.com/NBISweden/MrBayes.git", "d50016695db24c58bcb36c83c487bd365fe2a566"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/MrBayes
install_license ${WORKSPACE}/srcdir/MrBayes/COPYING

## MPI VERSION
if [[ "$target" == *-mingw* ]]; then
    COMPILER=${target}-gcc
    EXTRALIBS="-lm -lmsmpi -I${includedir} -L${libdir}"
else
    COMPILER=mpicc
    EXTRALIBS=""
fi

CC=$COMPILER \
LIBS="$EXTRALIBS" \
./configure \
    --with-mpi \
    --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --includedir="${includedir}" \
    --libdir="${libdir}"

make -j${nproc}
make install
install -Dvm 755 $bindir/mb${exeext} $bindir/mb_MPI${exeext} 

## SEQUENTIAL VERSION
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} --includedir="${includedir}" --libdir="${libdir}"
make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
filter!(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
filter!(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

products = [
    ExecutableProduct("mb", :mb),
    ExecutableProduct("mb_MPI", :mb_MPI),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"); platforms=filter(Sys.isbsd, platforms)),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
