# Note: this script will require BinaryBuilder.jl v0.3.0 or greater
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "jinja2cppwrapper"
version = v"1.1.0"
# Collection of sources required to build jinja2cppwrapper
sources = [
    GitSource("https://github.com/AlexKlo/Jinja2C.git", "a4b461b0b5d71750d6f29c65060766e6caa75848")
]

# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)
# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

#filter julia versions to include only Julia >= 1.9 for LTS
julia_versions = filter(v-> v >= v"1.9", julia_versions)

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Jinja2C

mkdir -p build/
cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

cmake --build build --parallel ${nproc}
cmake --install build
install_license /usr/share/licenses/MIT
"""

# Install a newer SDK which supports `shared_timed_mutex` and `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = filter(!Sys.iswindows, platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjinja2cppwrapper", :libjinja2cppwrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Jinja2Cpp_jll", uuid="72923777-883d-5a9e-8d94-bec813f4d578")),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p) || Sys.iswindows(p), platforms)),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_gcc_version=v"10")
