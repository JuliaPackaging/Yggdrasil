using BinaryBuilder

name = "LiquidDSP"
version = v"1.7.0"
sources = [
    GitSource("https://github.com/jgaeddert/liquid-dsp.git", "a8cc94a6f1f4386c294f5609dc2a373806cafd9c"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/liquid-dsp

#need to explicitly call patching
atomic_patch -p1 ../patches/NoPrint.patch

mkdir build
cd build 

#for all linux build, disable simd and any/all testing. not ideal with respect
#to simd but a complicated cmake. current linker error with windows and apple
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DFIND_SIMD=OFF -DENABLE_SIMD=OFF \
         -DBUILD_EXAMPLES=OFF -DBUILD_AUTOTESTS=OFF -DBUILD_BENCHMARKS=OFF

make -j${nproc}
make install

#need to specify license location
install_license ${WORKSPACE}/srcdir/liquid-dsp/LICENSE

"""

#linker error with windows, compiler issue with apple
platforms = supported_platforms( exclude=x->(Sys.isapple(x) || Sys.iswindows(x)) )

products = [
    LibraryProduct("libliquid", :libliquid),
]

dependencies = [
    Dependency("FFTW_jll"),
]

#requires gcc v8
build_tarballs(ARGS, name, version, sources, script, 
               platforms, products, dependencies, 
               julia_compat="1.7",
               preferred_gcc_version=v"8")
