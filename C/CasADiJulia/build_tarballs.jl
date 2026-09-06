using BinaryBuilder, Pkg

include("../../L/libjulia/common.jl")

name = "CasADiJulia"
version = v"3.8.0"

sources = [
    ArchiveSource(
        "https://github.com/casadi/casadi/releases/download/3.8.0/casadi-source-v3.8.0.zip",
        "5c22af75eecb88d0efcfb13b80c858475f219ebf5a32b05eae609eb01e23159f",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
install_license LICENSE.txt

# All three patches are forward-ports of fixes already made upstream, so they
# drop out of this recipe at the next CasADi release:
#   01 casadi_jl_dlext       the generated module hardcoded a Linux library
#                            filename; it now asks Julia for the extension.
#   02 casadi_jl_dup_methods the SWIG -julia backend emitted base-class
#                            forwarders for signatures the derived class already
#                            defines, so the forwarder silently overwrote the
#                            override (str/disp on Opti called SharedObject's).
#                            Julia >= 1.12 also refuses to precompile a module
#                            that overwrites a method, so this made the bindings
#                            unusable without __precompile__(false). Patch 02 is
#                            byte-for-byte what the fixed backend now generates.
#   03 casadi_native_body    ship the handwritten ergonomics layer as a body
#                            rather than a module, so the consuming package --
#                            itself named CasADiNative -- can splice it in.
#                            Including the wrapped file there would nest a
#                            same-named module inside itself, which Julia permits
#                            silently and which swallows every export. The same
#                            patch makes its re-export loop refer to the
#                            enclosing module instead of naming it.
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${f}"
done

pkgdir="${prefix}/share/CasADiJulia"
mkdir -p "${pkgdir}"

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

c++ "${flags[@]}" -o "${pkgdir}/libcasadi_wrap.${dlext}"

# Everything else ships verbatim, beside the wrapper, so each module's
# @__DIR__ lookup resolves inside the artifact.
install -Dm644 swig/julia/target/source/casadi.jl "${pkgdir}/casadi.jl"
install -Dm644 swig/julia/CasADiNative.jl "${pkgdir}/casadi_native_body.jl"
"""

# The wrapper uses Julia C API accessors whose inline definitions are tied to
# the Julia minor ABI. Each build covers every patch release in its minor line.
# 1.10 is the LTS, 1.12 the current release; 1.13 is still a prerelease here.
filter!(v -> v.minor in (10, 11, 12), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) != "riscv64" && !Sys.isfreebsd(p), platforms)

products = [
    LibraryProduct(
        "libcasadi_wrap",
        :libcasadi_wrap,
        "share/CasADiJulia";
        dont_dlopen=true,
    ),
    FileProduct(
        "share/CasADiJulia/casadi.jl",
        :casadi_jl,
    ),
    FileProduct(
        "share/CasADiJulia/casadi_native_body.jl",
        :casadi_native_body,
    ),
]

dependencies = [
    Dependency("CasADi_jll"; compat="=3.8.0"),
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
