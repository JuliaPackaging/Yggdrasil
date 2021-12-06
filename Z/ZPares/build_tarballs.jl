# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZPares"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cometscome/zpares_mirror.git", "ab453f5c3aa295bb43f6396e796db8d03964b5b3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd zpares_mirror/
cd originalfile/
tar -xvf zpares_0.9.6a.tar.gz 
cd zpares_0.9.6a
cp ../../wrapper/zpares_wrapper.f90 ./

if [[ $target == *"aarch64-apple-darwin"* ]]; then 
    Rankmismatch="-fallow-argument-mismatch"
fi


if [[ $target == *"apple-darwin"* ]]; then
    cp Makefile.inc/make.inc.gfortran.seq ./make.inc
    make BLAS="-L$libdir -lopenblas" USE_MPI="0" FFLAG="-O3 $Rankmismatch -dynamiclib -L$libdir -lopenblas" LAPACK="-L./"
    gfortran -O3 -dynamiclib -fPIC zpares_wrapper.f90 -I./include -L./lib -lzpares -L$libdir -lopenblas -o libzpares.dylib
    cp libzpares.dylib lib/
    cp lib/libzpares.dylib $prefix/lib/
    cp include/zpares.mod $prefix/include/
    cp zpares_wrapper.mod $prefix/include/
    cp lib/libzpares.a $prefix/lib/
elif [[ $target == *"w64-mingw32"* ]]; then 
    cp Makefile.inc/make.inc.gfortran.seq ./make.inc
    make BLAS="-L$libdir -lopenblas" LAPACK="-L$libdir -lopenblas" FFLAG="-O3 $Rankmismatch -shared -fPIC"
    gfortran -O3 -shared -fPIC zpares_wrapper.f90 -I./include -L./lib -lzpares  -L$libdir -lopenblas -o zpares_wrapper.a
    ld -shared -o zpares.so --whole-archive zpares_wrapper.a 
    cp lib/* $prefix/bin/
    cp zpares.so lib/
    cp lib/zpares.so $prefix/lib/libzpares.dll
    cp include/zpares.mod $prefix/include/
    cp zpares_wrapper.mod $prefix/include/
    cp lib/libzpares.a $prefix/lib/
else
    cp Makefile.inc/make.inc.gfortran.seq ./make.inc
    make BLAS="-L$libdir -lopenblas" LAPACK="-L$libdir -lopenblas" FFLAG="-O3 $Rankmismatch -shared -fPIC"
    gfortran -O3 -shared -fPIC zpares_wrapper.f90 -I./include -L./lib -lzpares  -o zpares_wrapper.a
    ld -shared -o zpares.so --whole-archive zpares_wrapper.a 
    cp zpares_wrapper.a $prefix/lib/
    cp zpares.so lib/
    cp lib/zpares.so $prefix/lib/libzpares.so
    cp include/zpares.mod $prefix/include/
    cp zpares_wrapper.mod $prefix/include/
    cp lib/libzpares.a $prefix/lib/
fi
"""


#    cp -r examples $prefix/
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_versions(; experimental=true)
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libzpares", :libzpares)]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
#build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
