# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CUTEst"
version = v"2.0.5" # <-- This is a lie, we're bumping to 2.0.5 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/ralna/ARCHDefs.git" ,"d4aa50f72626130f0e4fb6c8d31c622889a0ebbb"),
    GitSource("https://github.com/ralna/SIFDecode.git","affd441e93bd41f076239df2f4237fb13278f6a6"),
    GitSource("https://github.com/ralna/CUTEst.git"   ,"e6aff163eafd9424c70dfaf64a287252221cf597"),
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

# SIFDecode always looks for `ar`, `ranlib`, `sed` and `grep` in `/usr/bin/`
ln -sf $(which ar) /usr/bin/ar
ln -sf $(which ranlib) /usr/bin/ranlib
ln -sf $(which sed) /usr/bin/sed
ln -sf $(which grep) /usr/bin/grep

if [[ "${target}" == *-apple* ]]; then
  mkdir -p /opt/homebrew/bin
  ln -sf $(which gfortran) /opt/homebrew/bin/gfortran
fi

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
  echo "9" >> cutest.opts  # gcc
  export MYARCH=pc64.lnx.gfo
elif [[ "${target}" == *-apple* ]]; then
  echo "13" > cutest.opts  # macOS
  echo "2" >> cutest.opts  # gfortran
  echo "2" >> cutest.opts  # build all tools except Matlab
  echo "2" >> cutest.opts  # gcc
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
cd $CUTEST/objects/$MYARCH/single
gfortran -fPIC -shared ${extra} -Wl,${all_load} libcutest.a -Wl,${noall_load} -o ${libdir}/libcutest_single.${dlext}
cd $CUTEST/objects/$MYARCH/double
gfortran -fPIC -shared ${extra} -Wl,${all_load} libcutest.a -Wl,${noall_load} -o ${libdir}/libcutest_double.${dlext}

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

# The products that we will ensure are always built
products = [
    ExecutableProduct("sifdecoder", :sifdecoder),
    ExecutableProduct("slct", :slct),
    ExecutableProduct("clsf", :clsf),
    LibraryProduct("libcutest_single", :libcutest_single),
    LibraryProduct("libcutest_double", :libcutest_double),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
