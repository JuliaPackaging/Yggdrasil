using BinaryBuilder, Pkg

name = "MSTM"
version = v"4.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dmckwski/MSTM.git", "a33194e34e7929a4f3a00135388688e02085d4c5")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "$target" == *-mingw* ]]; then
    cd ${includedir}
    cp ${prefix}/src/mpi.f90 .
    gfortran -c -DWIN${nbits} -DINT_PTR_KIND=8 -fno-range-check mpi.f90
    cd ${WORKSPACE}/srcdir/MSTM/code
    if [[ ${target} == x86_64-* ]]; then
        cfg_stub="void __guard_check_icall_fptr(unsigned long ptr) { }"
        msmpifec=msmpifec64
        msmpi=msmpi64
    else
        cfg_stub="void __guard_check_icall_fptr(unsigned long ptr) { } void __security_check_cookie(void) { }"
        msmpifec=msmpifec
        msmpi=msmpi
    fi
    echo "${cfg_stub}" | gcc -x c -c -o cfg_stub.o -
    gfortran -O2 -fno-range-check mpidefs-parallel.f90 mstm-intrinsics.f90 mstm-v4.0.f90 cfg_stub.o -L${prefix}/lib -I${includedir} -l${msmpifec} -l${msmpi} -o "${bindir}/mstm${exeext}"
    rm ${includedir}/mpi.f90 ${includedir}/*.mod ${includedir}/*.o
else
    cd ${WORKSPACE}/srcdir/MSTM/code
    mpifort -O2 -fno-range-check mpidefs-parallel.f90 mstm-intrinsics.f90 mstm-v4.0.f90 -o "${bindir}/mstm${exeext}"
fi
install_license ${WORKSPACE}/srcdir/MSTM/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("mstm", :mstm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name = "MPICH_jll", uuid = "7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms = filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name = "MicrosoftMPI_jll", uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"); platforms = filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll", uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
