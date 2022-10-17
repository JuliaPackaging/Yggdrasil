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


install_license LICENSE
install -Dvm 755 vertex "${bindir}/vertex${exeext}"
install -Dvm 755 build "${bindir}/build${exeext}"
install -Dvm 755 actcor "${bindir}/actcor${exeext}"
install -Dvm 755 convex "${bindir}/convex${exeext}"
install -Dvm 755 ctransf "${bindir}/ctransf${exeext}"
install -Dvm 755 fluids "${bindir}/fluids${exeext}"
install -Dvm 755 frendly "${bindir}/frendly${exeext}"
install -Dvm 755 meemum "${bindir}/meemum${exeext}"
install -Dvm 755 pspts "${bindir}/pspts${exeext}"
install -Dvm 755 pssect "${bindir}/pssect${exeext}"
install -Dvm 755 pstable "${bindir}/pstable${exeext}"
install -Dvm 755 psvdraw "${bindir}/psvdraw${exeext}"
install -Dvm 755 pt2curv "${bindir}/pt2curv${exeext}"
install -Dvm 755 werami "${bindir}/werami${exeext}"

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
