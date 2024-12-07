using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PhyML"
version = v"3.3.20210610"
phyml_version = v"3.3.20210609" # latest passing build
hash = "eb1009ebef100d34696db95301ba7cb55dceeb40"
sources = [
    GitSource("https://github.com/stephaneguindon/phyml.git", hash),
    DirectorySource("./bundled")
]

script = raw"""
cd ${WORKSPACE}/srcdir/phyml
install_license ${WORKSPACE}/srcdir/phyml/COPYING

# disable -march=native flag
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done    

# generate config scripts
./autogen.sh

# make single-process version 
ac_cv_func_malloc_0_nonnull=yes \
ac_cv_func_realloc_0_nonnull=yes \
./configure --enable-phyml --prefix=$prefix --build=${MACHTYPE} --host=${target}
make clean & make -j${nproc}
install -Dvm 755 ./src/phyml${exeext} ${bindir}/phyml${exeext}

# make MPI version

if [[ "$target" == *-mingw* ]]; then
    COMPILER=${target}-gcc
    EXTRALIBS="-lmsmpi -I${includedir} -L${libdir}"
else 
    COMPILER=mpicc
    EXTRALIBS="" 
fi

ac_cv_func_malloc_0_nonnull=yes \
ac_cv_func_realloc_0_nonnull=yes \
./configure --enable-phyml-mpi --prefix=$prefix --build=${MACHTYPE} --host=${target}
make clean & make -j${nproc} CC=$COMPILER LIBS="${EXTRALIBS}"
install -Dvm 755 ./src/phyml-mpi${exeext} ${bindir}/phymlMPI${exeext}
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
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

products = [
    ExecutableProduct("phyml", :phyml),
    ExecutableProduct("phymlMPI", :phymlMPI),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
]
append!(dependencies, platform_dependencies)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6")
