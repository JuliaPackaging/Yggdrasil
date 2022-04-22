using BinaryBuilder, Pkg

name = "PhyML"
version = v"3.3.20210609" # latest passing build
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

platforms = supported_platforms()

products = [
    ExecutableProduct("phyml", :phyml),
    ExecutableProduct("phymlMPI", :phymlMPI),
]

dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
