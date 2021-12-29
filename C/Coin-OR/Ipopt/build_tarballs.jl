include("../coin-or-common.jl")

name = "Ipopt"
version = Ipopt_version

sources = [
    GitSource("https://github.com/coin-or/Ipopt.git", Ipopt_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Ipopt*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

LIBASL="-lasl"
if [[ "${target}" == *-linux-* ]]; then
  LIBASL="${LIBASL} -lrt"
fi

export CPPFLAGS="${CPPFLAGS} -I${includedir} -I${includedir}/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --enable-static \
    --with-pic \
    --disable-dependency-tracking \
    lt_cv_deplibs_check_method=pass_all \
    --with-lapack-lflags=-lblastrampoline \
    --with-mumps-cflags="-I${includedir}/mumps_seq" \
    --with-mumps-lflags="-ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis -lblastrampoline -lgfortran -lpthread" \
    --with-asl-lflags="${LIBASL}"

# parallel build fails
make
make install
"""

platforms = supported_platforms(;experimental=true)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libipopt", :libipopt),
    LibraryProduct("libipoptamplinterface", :libipoptamplinterface),
    ExecutableProduct("ipopt", :amplexe),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ASL_jll", ASL_version),
    Dependency("MUMPS_seq_jll", compat="=$(MUMPS_seq_version)"),
    Dependency("OpenBLAS32_jll", OpenBLAS32_version),
    Dependency("libblastrampoline_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = "1.6",
    init_block = """
    @static if VERSION < v"1.7.0-DEV.641"
            ccall((:lbt_forward, libblastrampoline), Int32, (Cstring, Int32, Int32),
                  OpenBLAS32_jll.libopenblas_path , 1, 0)
        end
    """
)
