# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ColPack"
version = v"0.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/amontoison/ColPack.git", "d873bad2a269355ccf30924ad18bd53a6abfe590")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ColPack/build/automake/
autoreconf -vif

mkdir build
cd build
../configure --enable-examples --build=${MACHTYPE} --host=${target}
make -j${nproc}

mkdir -p ${bindir}
cp ColPack${exeext} ${bindir}/ColPack${exeext}

if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    LDFLAGS=-lomp
else
    LDFLAGS=-lgomp
fi
${CXX} -shared $(flagon -Wl,--whole-archive) libcolpack.a $(flagon -Wl,--no-whole-archive) ${LDFLAGS} -o ${libdir}/libcolpack.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcolpack", :libcolpack),
    ExecutableProduct("ColPack", :ColPack)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems),
    # and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", clang_use_lld=false)
