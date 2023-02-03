# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.6"

# Collection of sources required to complete build
sources = [
            GitSource("https://github.com/Xyce/Xyce.git", "046a561ee2db376cf459edaeb8b6b67563da980d")
          ]

# Bash recipe for building across all platforms
script = raw"""
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}
cd $WORKSPACE/srcdir
apk add flex-dev
update_configure_scripts --reconf
install_license ${WORKSPACE}/srcdir/Xyce/COPYING
cd Xyce
./bootstrap
cd ..
mkdir buildx
cd buildx
/workspace/srcdir/Xyce/./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared --disable-mpi \
    LDFLAGS="-L${libdir} -lopenblas" \
    CPPFLAGS="-I/${includedir} -I/usr/include"
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Exclude some platforms that trigger internal compiler errors
platforms = filter(platforms) do p
    return !(arch(p) == "aarch64" && os(p) == "linux" && p["libgfortran_version"] ∈ ("3.0.0", "4.0.0"))
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libxyce", :libxyce),
    ExecutableProduct("Xyce", :Xyce)
]

# Dependencies that must be installed before this package can be built
dependencies = [
                    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"))
                    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
                    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
                    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
                    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat="1.6.0")
