using BinaryBuilder, Pkg

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
atomic_patch -p1 ../patches/FixWinCMAKE.patch

mkdir build
cd build 

#for all builds, disable simd and any/all testing. 
#not ideal with respect to simd but a complicated cmake otherwise. 
#need to set flags for aarch64-apple. 

if [[ "${target}" == *aarch64-apple* ]]; then 
   cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_EXE_LINKER_FLAGS="-L/opt/aarch64-apple-darwin20/aarch64-apple-darwin20/lib -lgcc_s.1.1" \
            -DCMAKE_SHARED_LINKER_FLAGS="-L/opt/aarch64-apple-darwin20/aarch64-apple-darwin20/lib -lgcc_s.1.1" \
            -DFIND_SIMD=OFF -DENABLE_SIMD=OFF \
            -DBUILD_EXAMPLES=OFF -DBUILD_AUTOTESTS=OFF -DBUILD_BENCHMARKS=OFF
else 
   cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DFIND_SIMD=OFF -DENABLE_SIMD=OFF \
            -DBUILD_EXAMPLES=OFF -DBUILD_AUTOTESTS=OFF -DBUILD_BENCHMARKS=OFF \
            -DCMAKE_C_STANDARD_LIBRARIES="" \
            -DCMAKE_CXX_STANDARD_LIBRARIES=""
fi

make -j${nproc}
make install

#need to specify license location
install_license ${WORKSPACE}/srcdir/liquid-dsp/LICENSE

"""

#linker error with windows
platforms = supported_platforms()
#platforms = supported_platforms( exclude=x->(!Sys.isapple(x)) )

products = [
    LibraryProduct("libliquid", :libliquid),
]

dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

#requires gcc v8
build_tarballs(ARGS, name, version, sources, script, 
               platforms, products, dependencies, 
               julia_compat="1.7",
               preferred_gcc_version=v"8")
