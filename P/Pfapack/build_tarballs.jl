# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "Pfapack"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xrq-phys/Pfapack.git", "ed885d81e31d88c86016f6664f7df08e50c32d6a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Pfapack

cmake fortran \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc} VERBOSE=1
make install

# Manual conversion from static to dynamic lib.
# Avoid linking libgfortran (these .f files make no reference to Fortran libs.)
cc -shared $(flagon -Wl,--whole-archive) ${prefix}/lib/libpfapack.a $(flagon -Wl,--no-whole-archive) \
    -o ${libdir}/libpfapack.${dlext} \
    -L${libdir} -lblastrampoline -lm

# Copy license file
install_license LapackLicence
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# No need to expand Fortran version since there code make no call to
# standard Fortran libraries
platforms = supported_platforms()

# Since we need to link to libblastrampoline which has seen multiple
# ABI-incompatible versions, we need to expand the julia versions we target
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]
function set_julia_version(platforms::Vector{Platform}, julia_version::VersionNumber)
    _platforms = deepcopy(platforms)
    for p in _platforms
        p["julia_version"] = string(julia_version)
    end
    return _platforms
end
expand_julia_versions(platforms::Vector{Platform}, julia_versions::Vector{VersionNumber}) =
    vcat(set_julia_version.(Ref(platforms), julia_versions)...)
platforms = expand_julia_versions(platforms, julia_versions)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpfapack", :libpfapack)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(get_addable_spec("libblastrampoline_jll", v"3.0.4+0"); platforms=filter(p -> VersionNumber(p["julia_version"]) == v"1.7.0", platforms)),
    Dependency(get_addable_spec("libblastrampoline_jll", v"5.1.1+0"); platforms=filter(p -> VersionNumber(p["julia_version"]) == v"1.8.0", platforms)),
    Dependency(get_addable_spec("libblastrampoline_jll", v"5.2.0+0"); platforms=filter(p -> VersionNumber(p["julia_version"]) >= v"1.9.0", platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
