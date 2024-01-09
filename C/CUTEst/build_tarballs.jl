# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.0.27"

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/ralna/ARCHDefs.git" ,"fe046f073a657c6f8a063e1875e929110b021d51"), # v2.2.1
    GitSource("https://github.com/ralna/SIFDecode.git","d88f40b1c4df2c07981812bb877cf49b92822fcb"), # v2.1.0
    GitSource("https://github.com/ralna/CUTEst.git"   ,"52274eea4334f2e8058385b3a7c9a8d11c3398b1"), # v2.0.27
]

# Bash recipe for building across all platforms
script = raw"""
echo "building for ${target}"

# setup
mkdir -p ${bindir}
mkdir -p ${libdir}

cp -r ARCHDefs ${prefix}
cp -r SIFDecode ${prefix}
cp -r CUTEst ${prefix}

export ARCHDEFS=${prefix}/ARCHDefs
export SIFDECODE=${prefix}/SIFDecode
export CUTEST=${prefix}/CUTEst

# ARCHDefs requires tput
apk update
apk add ncurses

# build SIFDecode
cd $SIFDECODE
echo "7" > sifdecode.opts  # Cross-compiler BinaryBuilder
echo "4" >> sifdecode.opts # Fortran compiler for BinaryBuilder
echo "nny" >> sifdecode.opts
./install_sifdecode < sifdecode.opts

# build CUTEst
cd $CUTEST
echo "7" > cutest.opts  # Cross-compiler BinaryBuilder
echo "4" >> cutest.opts # Fortran compiler for BinaryBuilder
echo "2" >> cutest.opts # Everything except Matlab support
echo "3" >> cutest.opts # C and C++ compilers for BinaryBuilder
echo "nnnydy" >> cutest.opts
export MYARCH=binarybuilder.bb.fc
./install_cutest < cutest.opts

# build shared libs
extra=""
if [[ "${target}" == *-apple-* ]]; then
  extra="-Wl,-undefined -Wl,dynamic_lookup -headerpad_max_install_names"
fi
cd $CUTEST/objects/$MYARCH/single
gfortran -fPIC -shared ${extra} $(flagon -Wl,--whole-archive) libcutest.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libcutest_single.${dlext}
cd $CUTEST/objects/$MYARCH/double
gfortran -fPIC -shared ${extra} $(flagon -Wl,--whole-archive) libcutest.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libcutest_double.${dlext}

ln -s $ARCHDEFS/bin/helper_functions ${bindir}/
ln -s $SIFDECODE/bin/sifdecoder ${bindir}/
ln -s $SIFDECODE/objects/$MYARCH/double/slct ${bindir}/
ln -s $SIFDECODE/objects/$MYARCH/double/clsf ${bindir}/
install_license $CUTEST/lgpl-3.0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# can't build shared libs on Windows, which imposes all symbols to be defined
platforms = expand_gfortran_versions(filter!(!Sys.iswindows, supported_platforms()))
# platforms = filter!(p -> !(os(p) == "freebsd" && libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sifdecoder", :sifdecoder),
    ExecutableProduct("slct", :slct),
    ExecutableProduct("clsf", :clsf),
    # LibraryProduct("libcutest_single", :libcutest_single),
    # LibraryProduct("libcutest_double", :libcutest_double),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
