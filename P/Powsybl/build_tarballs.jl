using BinaryBuilder, Pkg

name = "Powsybl"
version = v"0.2.0"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

pypowsybl_version = "BinariesDeployment"


sources = [
    GitSource("https://github.com/powsybl/powsybl.jl.git", "0a9e3110c366808e7ac23cfd9e19f51793807392"),
    GitSource("https://github.com/powsybl/pypowsybl.git", "2bd6ed8f64b335a52483237e99b75a98d04e7cc4"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-windows.zip",
                  "a4ddf94e91f785a456165f7732504526ac5b3761e5013771583e1cfbe44f26f1",
                  "powsybl-java-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "070831654779a53d504c8c9396bbabc1ab209fb2ffb4e9bea12dc9e39c36ddf1",
                  "powsybl-java-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "070831654779a53d504c8c9396bbabc1ab209fb2ffb4e9bea12dc9e39c36ddf1",
                  "powsybl-java-x86_64-linux-musl"), # linux package for gnu and musl
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-darwin.zip",
                  "e27ec64eb1962ff9d6d04aa11da1071687eef00a546312e969deea3f52b23267",
                  "powsybl-java-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-darwin-arm64.zip",
                  "dbd4ffbffee5a00b9e0b71f510189a4043ae648973415f60f8631418ac9991d2",
                  "powsybl-java-aarch64-apple-darwin20")
]

# To get julia_versions
include("../../L/libjulia/common.jl")

script = raw"""
cd $WORKSPACE/srcdir

# Get binary for powsybl-java, generated with GraalVm, install them in ${prefix} path
cp -rv powsybl-java-${target}/* ${prefix}

cd $WORKSPACE/srcdir/pypowsybl/cpp
cmake -B build \
    ${WORKSPACE}/srcdir/pypowsybl/cpp \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_PYPOWSYBL_JAVA=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    -DPYPOWSYBL_JAVA_LIBRARY_DIR=${prefix}/lib \
    -DPYPOWSYBL_JAVA_INCLUDE_DIR=${prefix}/include \
    -DCMAKE_INSTALL_PREFIX=${prefix}
cmake --build build --parallel ${nproc}
cmake --install build

# Build julia wrapper
cd $WORKSPACE/srcdir/powsybl.jl
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    cpp/powsybljl-cpp \
    -DJulia_PREFIX=${prefix} \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DPOWSYBL_INSTALL_DIR=${prefix}
cmake --build build --parallel ${nproc}
cmake --install build

install_license $WORKSPACE/srcdir/powsybl.jl/LICENSE.md
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

filter!(p -> (arch(p) == "x86_64" && os(p) ∈ ("windows", "linux", "macos")) || (arch(p) == "aarch64" && Sys.isapple(p)), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(["math", "libmath"], :libmath)
    LibraryProduct(["pypowsybl-java", "libpypowsybl-java"], :libpypowsybl_java)
    LibraryProduct(["powsybl-cpp", "libpowsybl-cpp"], :libpowsybl_cpp)
    LibraryProduct(["PowsyblJlWrap", "libPowsyblJlWrap"], :libPowsyblJlWrap)
]

dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("libjulia_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10", julia_compat="1.6")
