using BinaryBuilder, Pkg

name = "Powsybl"
version = v"0.2.0"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

pypowsybl_version = "1.12.0"


sources = [
    GitSource("https://github.com/powsybl/powsybl.jl.git", "19ec2f5aff90d42df5d90f85dda76f6007a13757"),
    GitSource("https://github.com/powsybl/pypowsybl.git", "cfc5f6b15e31d11f1879ba01fbf9e9f8032efd0b"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-windows.zip",
                  "467d269c52de4a3bcc73dc351f7f777357c5dda0311962b605f7262e3bde639d",
                  "powsybl-java-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "1f9a747255405cc3c4df7dd404fb5d58fc2a9843d7932dde6129d71ab33edac9",
                  "powsybl-java-x86_64-linux-gnu"),
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-linux.zip",
                  "1f9a747255405cc3c4df7dd404fb5d58fc2a9843d7932dde6129d71ab33edac9",
                  "powsybl-java-x86_64-linux-musl"), # linux package for gnu and musl
    ArchiveSource("https://github.com/powsybl/pypowsybl/releases/download/v$(pypowsybl_version)/binaries-v$(pypowsybl_version)-darwin.zip",
                  "e388a8638fd9834cb6dcf1c63d1189aee380d82e92956aff055757991a0ea409",
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

filter!(p -> (arch(p) == "x86_64" && os(p) ∈ ("windows", "linux")) || (arch(p) == "aarch64" && Sys.isapple(p)), platforms)
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
