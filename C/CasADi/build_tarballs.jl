using BinaryBuilder, Pkg

name = "CasADi"

version = v"3.5.5"

sources = [
    GitSource(
        "https://github.com/casadi/casadi.git",
        "fadc86444f3c7ab824dc3f2d91d4c0cfe7f9dad5",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/casadi

mkdir -p build
cd build

export CXXFLAGS="${CXXFLAGS} -std=c++11"
export CFLAGS="${CFLAGS} -fPIC"

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_IPOPT=ON \
    -DWITH_PYTHON=OFF \
    -DWITH_EXAMPLES=OFF \
    ..

if [[ "${target}" == *-linux-* ]]; then
        make -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build . --config Release
    else
        cmake --build . --config Release --parallel
    fi
fi
make install

cd $WORKSPACE/srcdir
${CXX} main.cpp -o ${bindir}/casadi_ipopt -I${includedir} -L${libdir} -lcasadi -std=c++11
"""

products = [
    ExecutableProduct("casadi_ipopt", :casadi_ipopt),
    LibraryProduct("libcasadi", :libcasadi),
    LibraryProduct("libcasadi_nlpsol_ipopt", :libcasadi_nlpsol_ipopt),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ipopt_jll"),
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
    preferred_gcc_version = v"6",
    julia_compat = "1.6",
)
