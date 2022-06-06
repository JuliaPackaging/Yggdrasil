using BinaryBuilder, Pkg

name = "MrBayes"
version = v"3.2.7"
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

platforms = supported_platforms()

products = [
    ExecutableProduct("mb", :mb),
    ExecutableProduct("mb_MPI", :mb_MPI),
]

dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
