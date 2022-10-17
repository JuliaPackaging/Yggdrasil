# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Perple_X"
version = v"6.9.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jadconnolly/Perple_X.git", "11eb2a349586d511ff170e7b67fd04e54eb3db82")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Perple_X/sources/
make -f makefile_691 

FilesArray=("vertex"  "build"  "actcor"  "convex" "ctransf" "fluids" "frendly" "meemum" "pspts" "pssect" "pstable" "psvdraw" "pt2curv" "werami")

if [[ "${target}" == *-mingw* ]]; then
    # this is non-ideal, but does the job (also due to lack of access to the source code)
    if test -f "vertex${exeext}"; then
        for file in ${FilesArray[*]}; do
            mv $file${exeext} $file
        done;
    fi
fi

install_license LICENSE
for file in ${FilesArray[*]}; do
    install -Dvm 755 $file "${bindir}/$file${exeext}"
done;

exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("fluids", :fluids),
    ExecutableProduct("meemum", :meemum),
    ExecutableProduct("pt2curv", :pt2curv),
    ExecutableProduct("pspts", :pspts),
    ExecutableProduct("actcor", :actcor),
    ExecutableProduct("ctransf", :ctransf),
    ExecutableProduct("frendly", :frendly),
    ExecutableProduct("vertex", :vertex),
    ExecutableProduct("build", :build),
    ExecutableProduct("pstable", :pstable),
    ExecutableProduct("psvdraw", :psvdraw),
    ExecutableProduct("pssect", :pssect),
    ExecutableProduct("werami", :werami),
    ExecutableProduct("convex", :convex)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
