# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROOT_julia"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
   GitSource("https://github.com/JuliaHEP/ROOT.jl.git", "26217370e35ab78c56d87f36cc14778eb798c5be")
]

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)
uuidopenssl = Base.UUID("458c3c95-2e84-50aa-8efc-19380b2a3a95")
delete!(Pkg.Types.get_last_stdlibs(v"1.12.0"), uuidopenssl)
delete!(Pkg.Types.get_last_stdlibs(v"1.13.0"), uuidopenssl)

# needed for julia_versions
include("../../L/libjulia/common.jl")

# Bash recipe for building across all platforms
script = raw"""

echo "USE_CCACHE: $USE_CCACHE"

cd "$WORKSPACE/srcdir/ROOT.jl/deps"

make -j `nproc` LDLIBS="-lcxxwrap_julia -lcxxwrap_julia_stl" LDFLAGS="-rdynamic" CXXFLAGS+="-I $WORKSPACE/destdir/include/julia -std=c++17 -fPIC"

cp -a build/libroot_julia.so "$prefix/lib/"

install_license $WORKSPACE/srcdir/ROOT.jl/LICENSE
"""

# Add to the recipe script commands to write the recipe in a file into the sandbox
# to ease debugging with the --debug build_tarballs.jl option.
scriptwrapper = """
cat > "\$WORKSPACE/recipe.sh" <<END_OF_SCRIPT
$script
END_OF_SCRIPT
chmod a+x "\$WORKSPACE/recipe.sh"
$script
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [ Platform("x86_64", "linux"; libc = "glibc", julia_version = julia_version) for julia_version in julia_versions ]

# The products that we will ensure are always built
products = [
    LibraryProduct("libroot_julia", :libroot_julia; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"),
               compat="0.14.3")
    Dependency(PackageSpec(name="ROOT_jll", uuid="45b42145-bbac-5752-8807-01f8b2702242"),
               compat="6.32.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, scriptwrapper, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6", skip_audit=true)
