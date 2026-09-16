using BinaryBuilder, Pkg

include("../../L/libjulia/common.jl")

name = "CasADiSWIG"
version = v"3.8.1"

sources = [
    ArchiveSource(
        "https://github.com/casadi/casadi/releases/download/$(version)/casadi-source-v$(version).zip",
        "ddc1f74971e36c02970c96a13e23b2577ea625823aac7ba8f02a31a5815a2a54",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
install_license LICENSE.txt

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/casadi_native_body.patch"

pkgdir="${prefix}/share/CasADiSWIG"
mkdir -pv "${pkgdir}"

flags=(
    -std=c++17
    -fPIC
    -shared
    -DWITH_DEPRECATED_FEATURES
    -I"${includedir}"
    -I"${includedir}/julia"
    swig/julia/target/source/casadiJULIA_wrap.cxx
    -L"${libdir}"
    -lcasadi
)

if [[ "${target}" == *-apple-* ]]; then
    flags+=(-undefined dynamic_lookup)
elif [[ "${target}" == *-mingw* ]]; then
    flags+=(-ljulia)
fi

${CXX} "${flags[@]}" -o "${pkgdir}/libcasadi_wrap.${dlext}"

# Everything else ships verbatim, beside the wrapper, so each module's
# @__DIR__ lookup resolves inside the artifact.
install -Dvm644 swig/julia/target/source/casadi.jl "${pkgdir}/casadi.jl"
install -Dvm644 swig/julia/CasADiNative.jl "${pkgdir}/casadi_native_body.jl"
"""

# The wrapper uses Julia C API accessors whose inline definitions are tied to
# the Julia minor ABI. Each build covers every patch release in its minor line.
filter!(v -> v.minor in (10, 11, 12), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
# Match the platforms available from CasADi_jll.
filter!(p -> arch(p) != "riscv64" && !Sys.isfreebsd(p), platforms)

products = [
    LibraryProduct(
        "libcasadi_wrap",
        :libcasadi_wrap,
        "share/CasADiSWIG";
        dont_dlopen=true,
    ),
    FileProduct(
        "share/CasADiSWIG/casadi.jl",
        :casadi_jl,
    ),
    FileProduct(
        "share/CasADiSWIG/casadi_native_body.jl",
        :casadi_native_body,
    ),
]

dependencies = [
    Dependency("CasADi_jll"; compat="=3.8.1"),
    BuildDependency("libjulia_jll"),
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
    preferred_gcc_version=v"8",
    julia_compat=libjulia_julia_compat(julia_versions),
)
