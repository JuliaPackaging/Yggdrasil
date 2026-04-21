using BinaryBuilder, Pkg

name = "CasADi"

version = v"3.7.2"

sources = [
    GitSource(
        "https://github.com/casadi/casadi.git",
        "f959d3175a444d763e4eda4aece48f4c5f4a6f90",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/casadi
install_license LICENSE.txt
mkdir -p build
cd build

CXX_STANDARD="-std=c++11"
CMAKE_CXX_STANDARD="11"
if [[ "${target}" == *"mingw"* ]]; then
    CXX_STANDARD="-std=c++14"
    CMAKE_CXX_STANDARD="14"
fi

export CXXFLAGS="-fPIC ${CXX_STANDARD}"
export CFLAGS="${CFLAGS} -fPIC"

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_BINDIR=${bindir} \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD} \
    -DWITH_IPOPT=ON \
    -DWITH_EXAMPLES=OFF \
    -DWITH_DEEPBIND=OFF \
    ..

make -j ${nproc}
make install

# Build amplexe
cd $WORKSPACE/srcdir
c++ main.cpp -o "${bindir}/amplexe${exeext}" \
    -I"${includedir}" \
    -L"${libdir}" \
    -lcasadi ${CXX_STANDARD}
"""

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
    LibraryProduct("libcasadi_nlpsol_ipopt", :libcasadi_nlpsol_ipopt),
]

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) != "riscv64" && 
    !(arch(p) == "aarch64" && Sys.isfreebsd(p)),
    platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"; compat="300.1400.400"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6",
)
