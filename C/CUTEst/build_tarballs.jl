# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CUTEst"
version = v"2.0.3"

# Collection of sources required to build ThinASLBuilder
sources = [
    "https://github.com/ralna/ARCHDefs/archive/v2.0.3x.tar.gz" =>
    "6583e27f84338447767bbdf4335514c8836ae4ad54f5e66280307e8b57189cff",
    "https://github.com/ralna/SIFDecode/archive/v2.0.3.tar.gz" =>
    "3a4aa817e1bf4e3595d0e4378da6172b65f02861f3a7c39f9da632a5cc31b1b2",
    "https://github.com/ralna/CUTEst/archive/v2.0.3.tar.gz" =>
    "d21a65c975302296f9856c09034cf46edc5da34b6efd96eed6cc94af6d2c8a55",
]

# Bash recipe for building across all platforms
script = raw"""
echo "building for ${target}"

# setup
mkdir -p ${prefix}/libexec
mkdir -p ${bindir}
mkdir -p ${libdir}
cp -r ARCHDefs-2.0.3x ${prefix}/libexec/
cp -r SIFDecode-2.0.3 ${prefix}/libexec/
cp -r CUTEst-2.0.3 ${prefix}/libexec/
export ARCHDEFS=${prefix}/libexec/ARCHDefs-2.0.3x
export SIFDECODE=${prefix}/libexec/SIFDecode-2.0.3
export CUTEST=${prefix}/libexec/CUTEst-2.0.3

# build SIFDecode
cd $SIFDECODE

if [[ "${target}" == *-linux* || "${target}" == *-freebsd* ]]; then
  echo "6" > sifdecode.opts   # PC64
  echo "2" >> sifdecode.opts  # Linux
  echo "5" >> sifdecode.opts  # gfortran
elif [[ "${target}" == *-apple* ]]; then
  echo "13" > sifdecode.opts  # macOS
  echo "2" >> sifdecode.opts  # gfortran
elif [[ "${target}" == *-mingw* ]]; then
  cd $ARCHDEFS
  cd $SIFDECODE
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
  echo "5" >> cutest.opts  # gfortran
  echo "2" >> cutest.opts  # build all tools except Matlab
  echo "7" >> cutest.opts  # gcc
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
all_load="--whole-archive"
noall_load="--no-whole-archive"
extra=""
if [[ "${target}" == *-apple-* ]]; then
    all_load="-all_load"
    noall_load="-noall_load"
    extra="-Wl,-undefined -Wl,dynamic_lookup -headerpad_max_install_names"
fi
cd $CUTEST/objects/$MYARCH/double
gfortran -fPIC -shared ${extra} -Wl,${all_load} libcutest.a -Wl,${noall_load} -o libcutest_double.${dlext}
cd $CUTEST/objects/$MYARCH/single
gfortran -fPIC -shared ${extra} -Wl,${all_load} libcutest.a -Wl,${noall_load} -o libcutest_single.${dlext}

ln -s $SIFDECODE/bin/sifdecoder ${bindir}/
ln -s $SIFDECODE/objects/$MYARCH/double/slct ${bindir}/
ln -s $SIFDECODE/objects/$MYARCH/double/clsf ${bindir}/
install_license $CUTEST/lgpl-3.0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# can't build shared libs on Windows, which imposes all symbols to be defined
platforms = expand_gfortran_versions(filter!(p -> !isa(p, Windows), supported_platforms()))

# The products that we will ensure are always built
products = [
    ExecutableProduct("sifdecoder", :sifdecoder),
    ExecutableProduct("slct", :slct),
    ExecutableProduct("clsf", :clsf),
]

dependencies = [
    BuildDependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
