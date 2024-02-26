using BinaryBuilder, Pkg

name = "JSBSim"
version = v"1.1.12"

julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

# Collection of sources required to build JSBSim
sources = [
    GitSource("https://github.com/JSBSim-Team/jsbsim.git",
              "133fcff53ae15abcbbbd4d06390e1b59ab76e5c6"),
]

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jsbsim
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DCMAKE_CXX_FLAGS_RELEASE="-D_POSIX_C_SOURCE")
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DOCS=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DBUILD_JULIA_PACKAGE=ON \
    -DJulia_PREFIX=${prefix} \
    "${FLAGS[@]}" \
    ..
cmake --build . --target JSBSimJL -- -j${nproc}
install_license $WORKSPACE/srcdir/jsbsim/COPYING
cp julia/*JSBSimJL*.$dlext $libdir/.
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> libc(p) != "musl" && !Sys.isfreebsd(p), platforms) # muslc is not supported

# The products that we will ensure are always built
products = [
    LibraryProduct("libJSBSimJL", :libJSBSimJL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = julia_compat)
