# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder,Pkg

name = "NRLMSIS"
version = v"2.1"

# Please see a description at https://ccmc.gsfc.nasa.gov/models/NRLMSIS~v2.0/
# This is the 2.1 version 
sources = [
    ArchiveSource("https://map.nrl.navy.mil/map/pub/nrl/NRLMSIS/NRLMSIS2.1/nrlmsis2.1.tar.gz",
                  "41e47b29f795d36a5cc252b2858aa2a384c4a7323ace3d48d3ea2f2b37a1a6a8")
]

script = raw"""
cd $WORKSPACE/srcdir
install_license nrlmsis2.1_license..txt
mkdir -p ${libdir}
FFLAGS="--shared -fPIC -O3 -cpp"
$FC $FFLAGS msis_constants.F90 msis_utils.F90 msis_init.F90 msis_gfn.F90 msis_tfn.F90 msis_dfn.F90 msis_calc.F90 msis_gtd8d.F90 \
    -o ${libdir}/nrlmsis.${dlext}
"""

# For testing with local deployment:
# platforms = [Platform("x86_64", "linux", libgfortran_version="5.0.0")]
platforms = [
             Platform("x86_64", "linux"),
             Platform("x86_64", "linux"; libc="musl"),
             Platform("x86_64", "macOS"),
             Platform("x86_64", "Windows")
            ]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("nrlmsis", :nrlmsis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
