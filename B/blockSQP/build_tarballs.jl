using BinaryBuilder, Pkg

name = "libblocksqp"
version = v"0.0.1"
sources = [
    GitSource("https://github.com/djanka2/blockSQP.git", "da05d3957b93bd55b9a7f08c859d302851056a6d"),
    GitSource("https://github.com/mathopt/blockSQPWrapper.git", "02e97255af77f508f3ebfafc7e1ffc661738cf29"),
]

include("../../L/libjulia/common.jl")

script = raw"
cd ${WORKSPACE}/srcdir
mv blockSQPWrapper/CMakeLists.txt blockSQP/CMakeLists.txt
mv blockSQPWrapper/blockSQP_julia.cpp blockSQP/src/blockSQP_julia.cpp
cd blockSQP
mkdir build && cd build

BLASLIBNAME=\"libblastrampoline\"
if [ ! -f ${libdir}/${BLASLIBNAME}.${dlext} ]; then
    echo \"${libdir}/${BLASLIBNAME}.${dlext} not found.\"
    if [[ \"${target}\" == *-mingw* ]]; then
        BLASLIBNAME=\"libblastrampoline-5\"
    fi
fi


if [[ \"${nbits}\" == 64 ]]; then

    SYMB_DEFS=()
    if [[ \"${target}\" != *-apple-* ]]; then
        for sym in cblas_dgemm; do
            SYMB_DEFS+=(\"-D${sym}=${sym}64_\")
        done
    fi
    if [[ \"${target}\" == *-apple-* ]] || [[ \"${target}\" == *-mingw* ]]; then
        FLAGS+=(-DALLOW_OPENBLAS_MACOS=ON)
    fi


    export CXXFLAGS=\"${SYMB_DEFS[@]}\"

fi

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_PREFIX_PATH=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DLAPACK_LIBRARIES=${libdir}/${BLASLIBNAME}.${dlext}\
    -DBLAS_LIBRARIES=${libdir}/${BLASLIBNAME}.${dlext} \
    ..

make
make install
install_license ${WORKSPACE}/srcdir/blockSQP/LICENSE
"

platforms = vcat(libjulia_platforms.(julia_versions[julia_versions .>= v"1.10.0"])...)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(p -> !(libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(p -> !(os(p) == "freebsd"), platforms)



dependencies = [
    Dependency("qpOASES_jll"),
    Dependency("libblastrampoline_jll"; compat="5.4"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13"),
    BuildDependency(PackageSpec(name="libjulia_jll"))
]

products = [
    LibraryProduct("libblockSQP", :libblockSQP)
    LibraryProduct("libblockSQP_wrapper", :libblockSQP_wrapper)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        julia_compat="1.10", preferred_gcc_version=v"9")
