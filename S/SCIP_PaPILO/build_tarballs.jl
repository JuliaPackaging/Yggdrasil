# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP_PaPILO"

version = v"0.1.0"

sources = [
    ArchiveSource("https://scipopt.org/download/release/scipoptsuite-v800-rc16.tgz", "0fc025f260e9e77e26e5d218707c04d03492e792c793d34221ada09fbb275b99"),
]

# Bash recipe for building across all platforms
script = raw"""
cd scipoptsuite*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DZIMPL=OFF\
  -DUG=0\
  -DAMPL=0\
  -DSYM=bliss\
  -DIPOPT_DIR=${prefix} -DIPOPT_LIBRARIES=${libdir} ..
make -j${nproc}
make install

mkdir -p ${prefix}/share/licenses/SCIP_PaPILO
for dir in papilo scip soplex; do
    cp $WORKSPACE/srcdir/scipoptsuite*/${dir}/COPYING ${prefix}/share/licenses/SCIP_PaPILO/LICENSE_${dir}
done
cp $WORKSPACE/srcdir/scipoptsuite*/gcg/LICENSE ${prefix}/share/licenses/SCIP_PaPILO/LICENSE_gcg
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

filter!(platforms) do p
    !occursin("arm", arch(p)) && !occursin("windows", p.tags["os"]) && libc(p) != "musl"
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("papilo", :papilo),
    ExecutableProduct("scip", :scip),
    LibraryProduct("libscip", :libscip),
    LibraryProduct("libgcg", :libgcg),
]

dependencies = [
    Dependency(PackageSpec(name="bliss_jll", uuid="508c9074-7a14-5c94-9582-3d4bc1871065")),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.76.0"),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.7"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.1.2"),
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7")),
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e")),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"7",
    julia_compat="1.6",
)
