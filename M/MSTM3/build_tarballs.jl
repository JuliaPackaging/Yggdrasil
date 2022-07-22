# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MSTM3"
version = v"3.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.eng.auburn.edu/~dmckwski/scatcodes/mstm%20v3.0.zip", "ed3b046ef80bc3260849cb7bd2d5629aedf386c0f31bf7a9dc347c8a8e31ee9b")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "$target" == *-mingw* ]]; then
    cd ${includedir}
    cp ${prefix}/src/mpi.f90 .
    gfortran -c -DWIN${nbits} -DINT_PTR_KIND=8 -fno-range-check mpi.f90
    cd ${WORKSPACE}/srcdir
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
    gfortran -O2 -fno-range-check mpidefs-parallel-v3.0.f90 mstm-intrinsics-v3.0.f90 mstm-modules-v3.0.f90 mstm-main-v3.0.f90 cfg_stub.o -L${prefix}/lib -I${includedir} -l${msmpifec} -l${msmpi} -o "${bindir}/mstm3${exeext}"
    rm ${includedir}/mpi.f90 ${includedir}/*.mod ${includedir}/*.o
else
    cd ${WORKSPACE}/srcdir
    mpifort -O2 -fno-range-check mpidefs-parallel-v3.0.f90 mstm-intrinsics-v3.0.f90 mstm-modules-v3.0.f90 mstm-main-v3.0.f90 -o "${bindir}/mstm3${exeext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(x -> libgfortran_version(x) != v"4.0.0", expand_gfortran_versions(supported_platforms()))

# The products that we will ensure are always built
products = [
    ExecutableProduct("mstm3", :mstm3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid="9237b28f-5490-5468-be7b-bb81f5f5e6cf"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
