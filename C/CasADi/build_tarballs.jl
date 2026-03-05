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

export CXXFLAGS="-fPIC -std=c++11"
export CFLAGS="${CFLAGS} -fPIC"

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_IPOPT=ON \
    -DWITH_EXAMPLES=OFF \
    -DWITH_DEEPBIND=OFF \
    ..

make -j ${nproc}
make install

cd $WORKSPACE/srcdir

c++ main.cpp -o "${bindir}/amplexe${exeext}" -I"${includedir}" -L"${libdir}" -lcasadi -std=c++11
"""

products = [
    ExecutableProduct("amplexe", :amplexe),
    LibraryProduct("libcasadi", :libcasadi),
    LibraryProduct("libcasadi_nlpsol_ipopt", :libcasadi_nlpsol_ipopt),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(platforms) do p
    # Windows export bug is:
    #   https://gcc.gnu.org/bugzilla/show_bug.cgi?id=50044
    # because of
    #   https://github.com/casadi/casadi/blob/402fe583f0d3cf1fc77d1e1ac933f75d86083124/casadi/core/dm_instantiator.cpp#L373-L374
    return !Sys.iswindows(p)
end

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
    preferred_gcc_version = v"6",
    julia_compat = "1.6",
)
