using BinaryBuilder, Pkg

name = "slope"
version = v"5.1.1"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

sources = [
    GitSource("https://github.com/jolars/libslope.git", "e668b0891ff744cad2d1b3fbf13bf2ec534f1518"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz", "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
]

# Bash recipe for building across all platforms
script = raw"""
# `std::optionals()`'s `value()` needs macOS 10.14 SDK
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    mkdir -p "/opt/${target}/${target}/sys-root/System"
    rsync -a --ignore-errors usr/* "/opt/${target}/${target}/sys-root/usr/." || true
    rsync -a --ignore-errors System/ "/opt/${target}/${target}/sys-root/System/" || true
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

cd $WORKSPACE/srcdir/libslope

# Build main library
cmake -B build \
    -DBUILD_TESTING=OFF \
    -DBUILD_JULIA_BINDINGS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \

cmake --build build --parallel ${nproc}
cmake --install build

install_license $WORKSPACE/srcdir/libslope/LICENSE
"""

include("../../L/libjulia/common.jl")
julia_versions = filter(v -> v >= v"1.10", julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libslopejll", :libslopejll),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("libjulia_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LLVMOpenMP_jll", platforms=filter(Sys.isapple, platforms)),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.3"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"11", julia_compat="1.10")
