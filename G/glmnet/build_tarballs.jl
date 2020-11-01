# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "glmnet"
version = v"4.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cran/glmnet.git", "b1a4b50de01e0cd24343959d7cf86452bac17b26")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glmnet/src

# Add stub for `setpb`, which normally comes from `pb.c` to connect the 
# progress meter to R, but we don't need that
echo "
      subroutine setpb(val)
      return
      end
" > pb.f

flags="-fdefault-real-8 -ffixed-form -shared -O3"
if [[ ${target} != *mingw* ]]; then
    flags="${flags} -fPIC";
fi
if [[ ${target} != aarch64* ]] && [[ ${target} != arm* ]]; then
    flags="${flags} -m${nbits}";
fi
mkdir -p ${libdir}
${FC} ${LDFLAGS} ${flags} glmnet5dpclean.f wls.f pb.f -o ${libdir}/libglmnet.${dlext}
install_license DESCRIPTION
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libglmnet", :libglmnet)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
