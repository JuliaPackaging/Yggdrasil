using BinaryBuilder, Pkg

name = "HPTT"
version = v"1.0.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/springer13/hptt.git", "a55c2a927d5462e81abeb12081fd345024caf5f6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
atomic_patch -p1 $WORKSPACE/srcdir/patches/clang_compatibility.patch
mkdir -p ${libdir}
mkdir -p ${includedir}
export hpttdir=${WORKSPACE}/srcdir/hptt
cp ${hpttdir}/include/* ${includedir}
export CXXFLAGS="-O3 -std=c++11 -DNDEBUG -fopenmp -fPIC"
if [[ ${proc_family} == intel ]]; then
    export CXXFLAGS="$CXXFLAGS -mavx -DHPTT_ARCH_AVX"
elif [[ ${proc_family} == power ]]; then
    export CXXFLAGS="$CXXFLAGS -DHPTT_ARCH_IBM -maltivec -mabi=altivec";
## specific arm optimizations seem to be broken in library
# elif [[ ${target} == arm* ]]; then
#     export CXXFLAGS="$CXXFLAGS -mfpu=neon -DHPTT_ARCH_ARM"
fi
for f in ${hpttdir}/src/*.cpp; do
    $CXX $CXXFLAGS -I ${includedir} -c $f -o ${f%.cpp}.o
done
$CXX ${hpttdir}/src/*.o $CXXFLAGS -o ${libdir}/libhptt.$dlext -shared
install_license ${hpttdir}/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhptt", :libhptt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat="1.6")
