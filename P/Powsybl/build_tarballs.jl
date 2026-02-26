using BinaryBuilder, Pkg

name = "Powsybl"
version = v"0.3.0"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

pypowsybl_version = "1.14.0"


# Powsybl is a java framework, built to native binaries using GraalVm native image. This building process cannot be done in binary builder. Prebuilt binaries are retrieved from pypowsybl release.
sources = [
    GitSource("https://github.com/powsybl/powsybl.jl.git", "70503bf17751430d4c00f7345986bd574cbdb3ef"),
    GitSource("https://github.com/powsybl/pypowsybl.git", "342fb354a7c9f9bdfdec66d5901005293848d64b"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-windows.zip",
                  "4b4a8c1b2bc9a210902773bda3f14a4131e48fb54a453857164c7d90fa8114e3",
                  "powsybl-java-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "0edba1422152bd3c8fe17f5fa79ecdfbb2ab7a96391941c5d74bfdaf4075b108",
                  "powsybl-java-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "0edba1422152bd3c8fe17f5fa79ecdfbb2ab7a96391941c5d74bfdaf4075b108",
                  "powsybl-java-x86_64-linux-musl"), # linux package for gnu and musl
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-darwin.zip",
                  "ce3a9254fabce9dec84ca4c39aaa1879e1b26bde12c403f3b9c10c443ce6d7a0",
                  "powsybl-java-x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-darwin-arm64.zip",
                  "ec1afab2bb092e422b001ca75486bf2b880979b36d7c5dc4159eb43c8cc72983",
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
