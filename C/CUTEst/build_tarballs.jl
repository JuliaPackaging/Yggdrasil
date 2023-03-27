# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.0.6" # <-- This is a lie, we're bumping to 2.0.6 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/ralna/ARCHDefs.git" ,"5ab94bbbe45e13c1d00acdc09b8b7df470b98c29"),
    GitSource("https://github.com/ralna/SIFDecode.git","42d3241205dc56e1f943687293e95586755a3c10"),
    GitSource("https://github.com/ralna/CUTEst.git"   ,"1d2954ef69cfd541d3ec2299d29da7302cb8b6a3"),
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
if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
  echo "6" > sifdecode.opts   # PC64
  echo "2" >> sifdecode.opts  # Linux
  echo "6" >> sifdecode.opts  # gfortran
elif [[ "${target}" == *-apple* ]]; then
  echo "13" > sifdecode.opts  # macOS
  echo "2" >> sifdecode.opts  # gfortran
elif [[ "${target}" == *-mingw* ]]; then
  echo "6" > sifdecode.opts   # PC64
  echo "1" >> sifdecode.opts  # Windows
  echo "3" >> sifdecode.opts  # gfortran
fi
echo "nny" >> sifdecode.opts
./install_sifdecode < sifdecode.opts

# build CUTEst
cd $CUTEST
if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
  echo "6" > cutest.opts   # PC64
  echo "2" >> cutest.opts  # Linux
  echo "6" >> cutest.opts  # gfortran
  echo "2" >> cutest.opts  # build all tools except Matlab
  echo "8" >> cutest.opts  # gcc
  export MYARCH=pc64.lnx.gfo
elif [[ "${target}" == *-apple* ]]; then
  echo "13" > cutest.opts  # macOS
  echo "2" >> cutest.opts  # gfortran
  echo "2" >> cutest.opts  # build all tools except Matlab
  echo "5" >> cutest.opts  # gcc
  export MYARCH=mac64.osx.gfo
elif [[ "${target}" == *-mingw* ]]; then
  echo "5" > cutest.opts   # PC64
  echo "1" >> cutest.opts  # Windows
  echo "3" >> cutest.opts  # gfortran
  echo "2" >> cutest.opts  # build all tools except Matlab
  echo "5" >> cutest.opts  # gcc
  export MYARCH=pc64.mgw.gfo
fi
echo "nnydy" >> cutest.opts
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
platforms = filter!(p -> !(os(p) == "freebsd" && libgfortran_version(p) == v"3"), platforms)

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
