using BinaryBuilder
using Pkg

name = "SPRAL"
version = v"0.1.0"

## Sources
sources = [
    GitSource("https://github.com/lanl-ansi/spral.git", "3842fffd5b16f0bf85be6f4b2832816ac4405763"), # master
]

script = raw"""
# ===== BUILD SPRAL =====
# Follow the instruction: https://github.com/lanl-ansi/spral/blob/master/COMPILE.md
cd ${WORKSPACE}/srcdir/spral*
update_configure_scripts

mkdir build
./autogen.sh
CFLAGS=-fPIC CPPFLAGS=-fPIC CXXFLAGS=-fPIC FFLAGS=-fPIC FCFLAGS=-fPIC \
    ./configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
    --with-blas="-L${libdir} -lopenblas" --with-lapack="-L${libdir} -lopenblas" \
    --with-metis="-L${libdir} -lmetis" \
    --with-metis-inc-dir="-I${prefix}/include"
make && make install
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
     LibraryProduct("spral_ssids", :spral_ssids)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name = "METIS_jll",
                                uuid = "d00139f3-1899-568f-a2f0-47f597d42d70",
                                version = v"4.0.3")),
    Dependency("OpenBLAS32_jll"),
    Dependency("Hwloc_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6")
