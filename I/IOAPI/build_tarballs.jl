# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "IOAPI"
version = v"3.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cjcoats/ioapi-3.2.git", "ef5d5f4e112c249b593b19426421f25d79ae094b")
]

# Bash recipe for building across all platforms
script = raw"""
apk add tcsh # Build script is in csh

cd $WORKSPACE/srcdir/ioapi-3.2/ioapi/
install_license ../LICENSE
export HOME=${WORKSPACE}/srcdir
export BIN=tmp
export BINDIR=${HOME}/ioapi-3.2/${BIN}
mkdir $BINDIR

sed -i 's/-ffast-math /-fPIC /g' Makeinclude* # Get rid of forbidden -ffast-math flag
sed -i 's/-DNEED_ARGS=1/-DNEED_ARGS=1 -DIOAPI_NCF4=1/g' Makeinclude* # Specify NetCDF v4

if [[ "${nbits}" == 32 ]]; then
    sed -i 's/-m64/-m32/g' Makeinclude* # Specify 32-bit build
elif [[ "${target}" == *aarch64* ]]; then
    sed -i 's/-m64//g' Makeinclude* # Get rid of x86 flag
fi

if [[ "${target}" == *mingw* ]]; then
    # Add missing stdint header.
    sed -i 's/<stdio.h>/<stdio.h>\n\#include <stdint.h>/g' bufint3.c

    # This sys/wait.h header is not available and doesn't seem to be used.
    sed -i 's/\#include <sys\/wait.h>//g' systemf.c
fi

cp Makefile.nocpl Makefile
cp Makeinclude.Linux2_x86_64gfort Makeinclude.$BIN

make # Parallel make (-j > 1) does not work

cp *.h ${includedir} # C header files
cp fixed_src/* ${includedir} # FORTRAN .EXT (include) files

# Convert static library to dynamic library
if [[ "${target}" == *-apple-* ]]; then
    gfortran -shared -fPIC -fopenmp -o ${libdir}/libioapi.${dlext} -L${libdir} -Wl,$(flagon --whole-archive) ${BINDIR}/libioapi.a -lnetcdf -lnetcdff
else
    gfortran -shared -fPIC -fopenmp -o ${libdir}/libioapi.${dlext} -L${libdir} -Wl,$(flagon --whole-archive) ${BINDIR}/libioapi.a -Wl,$(flagon --no-whole-archive) -lnetcdf -Wl,$(flagon --no-whole-archive) -lnetcdff
fi
rm ${BINDIR}/libioapi.a

cd ../m3tools/
cp Makefile.nocpl Makefile
make

cd $BINDIR

rm *.o 
mv *.mod ${includedir} # Move FORTRAN mod files to include dir, they are used by some dependencies
mv * $bindir # Move executables to bindir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "linux"; libc = "glibc"),
    #Platform("x86_64", "windows"),
    #Platform("i686", "windows")
]
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("dayagg", :dayagg),
    ExecutableProduct("wrftom3", :wrftom3),
    ExecutableProduct("kfxtract", :kfxtract),
    ExecutableProduct("m3combo", :m3combo),
    ExecutableProduct("m3wndw", :m3wndw),
    ExecutableProduct("wrfgriddesc", :wrfgriddesc),
    ExecutableProduct("m3probe", :m3probe),
    ExecutableProduct("m3agmax", :m3agmax),
    ExecutableProduct("m3totxt", :m3totxt),
    ExecutableProduct("timediff", :timediff),
    ExecutableProduct("factor", :factor),
    ExecutableProduct("presz", :presz),
    ExecutableProduct("presterp", :presterp),
    ExecutableProduct("gregdate", :gregdate),
    ExecutableProduct("m3stat", :m3stat),
    ExecutableProduct("m3pair", :m3pair),
    ExecutableProduct("projtool", :projtool),
    LibraryProduct("libioapi", :libioapi),
    ExecutableProduct("datshift", :datshift),
    ExecutableProduct("juldate", :juldate),
    ExecutableProduct("m3cple", :m3cple),
    ExecutableProduct("wndwdesc", :wndwdesc),
    ExecutableProduct("mpasstat", :mpasstat),
    ExecutableProduct("vertintegral", :vertintegral),
    ExecutableProduct("jul2greg", :jul2greg),
    ExecutableProduct("m3fake", :m3fake),
    ExecutableProduct("m3merge", :m3merge),
    ExecutableProduct("greg2jul", :greg2jul),
    ExecutableProduct("latlon", :latlon),
    ExecutableProduct("mpasdiff", :mpasdiff),
    ExecutableProduct("airs2m3", :airs2m3),
    ExecutableProduct("m3edhdr", :m3edhdr),
    ExecutableProduct("m3diff", :m3diff),
    ExecutableProduct("randomstat", :randomstat),
    ExecutableProduct("mtxbuild", :mtxbuild),
    ExecutableProduct("mtxcple", :mtxcple),
    ExecutableProduct("insertgrid", :insertgrid),
    ExecutableProduct("m3xtract", :m3xtract),
    ExecutableProduct("vertot", :vertot),
    ExecutableProduct("juldiff", :juldiff),
    ExecutableProduct("camxtom3", :camxtom3),
    ExecutableProduct("mpastom3", :mpastom3),
    ExecutableProduct("vertimeproc", :vertimeproc),
    ExecutableProduct("findwndw", :findwndw),
    ExecutableProduct("m3hdr", :m3hdr),
    ExecutableProduct("m3tproc", :m3tproc),
    ExecutableProduct("mtxblend", :mtxblend),
    ExecutableProduct("selmrg2d", :selmrg2d),
    ExecutableProduct("m3tshift", :m3tshift),
    ExecutableProduct("timeshift", :timeshift),
    ExecutableProduct("julshift", :julshift),
    ExecutableProduct("bcwndw", :bcwndw),
    ExecutableProduct("gridprobe", :gridprobe),
    ExecutableProduct("m3agmask", :m3agmask),
    ExecutableProduct("m3interp", :m3interp),
    ExecutableProduct("m3mask", :m3mask),
    ExecutableProduct("mtxcalc", :mtxcalc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="400.701.400 - 400.799")
    Dependency(PackageSpec(name="NetCDFF_jll", uuid="78e728a9-57fe-5d11-897c-5014b89e5f84"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    # `MbedTLS_jll` is an indirect dependency through NetCDF, we need to specify
    # a compatible build version for this to work.
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version=v"2.24.0"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
