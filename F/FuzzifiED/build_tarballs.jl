# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FuzzifiED"
version = v"0.10.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mankai-chow/FuzzifiED_Fortran.git", "32970bd69f9cc2a17e840399fb973a01535078c0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FuzzifiED_Fortran/src/
FFLAGS=(-O3 -fPIC -fopenmp)
if [[ ${nbits} == 64 ]]; then
    FFLAGS+=(-fdefault-integer-8)
fi
for src in cfs.f90 bs.f90 op.f90 diag.f90 diag_re.f90 ent.f90; do
    gfortran "${FFLAGS[@]}" -c ./${src}
done
gfortran "${FFLAGS[@]}" -shared -o "${libdir}/libfuzzified.${dlext}" ./*.o -L "${libdir}" -larpack
cd super
for src in scfs.f90 sbs.f90 sop.f90; do
    gfortran "${FFLAGS[@]}" -c ./${src}
done
gfortran "${FFLAGS[@]}" -shared -o "${libdir}/libfuzzifino.${dlext}" ./*.o
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfuzzified", :LibpathFuzzifiED),
    LibraryProduct("libfuzzifino", :LibpathFuzzifino),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="Arpack_jll", uuid="68821587-b530-5797-8361-c406ea357684"); compat="~3.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
