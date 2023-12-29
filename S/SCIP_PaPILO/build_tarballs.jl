# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP_PaPILO"

version = v"800.100.000"

sources = [
    ArchiveSource(
        "https://scipopt.org/download/release/scipoptsuite-8.1.0.tgz",
        "a3c1b45220252865d4cedf41d6327b6023608feb360d463f2e68ec4ac41cda06"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd scipoptsuite*

# for soplex threadlocal
export CXXFLAGS="-DTHREADLOCAL=''"

# can be removed for scip 805
echo "target_link_libraries(clusol gfortran)" >> papilo/CMakeLists.txt

if [[ "${target}" == *apple-darwin* ]]; then
    # See <https://github.com/JuliaPackaging/Yggdrasil/issues/7745>:
    # Remove the new linkers which don't work yet
    rm /opt/bin/${bb_full_target}/ld64.lld
    rm /opt/bin/${bb_full_target}/ld64.${target}
    rm /opt/bin/${bb_full_target}/${target}-ld64.lld
    rm /opt/${MACHTYPE}/bin/ld64.lld
fi

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DZIMPL=OFF\
  -DUG=0\
  -DAMPL=0\
  -DGCG=0\
  -DBOOST=ON\
  -DSYM=bliss\
  -DTPI=tny\
  -DIPOPT_DIR=${prefix} \
  -DIPOPT_LIBRARIES=${libdir} \
  -DBLISS_INCLUDE_DIR=${includedir} \
  -DBLISS_LIBRARY=bliss \
  ..
make -j${nproc} scip
make papilo-executable

make install
cp bin/papilo${exeext} "${bindir}/papilo${exeext}"

mkdir -p ${prefix}/share/licenses/SCIP_PaPILO
for dir in scip soplex gcg; do
    cp $WORKSPACE/srcdir/scipoptsuite*/${dir}/LICENSE ${prefix}/share/licenses/SCIP_PaPILO/LICENSE_${dir}
done
cp $WORKSPACE/srcdir/scipoptsuite*/papilo/COPYING ${prefix}/share/licenses/SCIP_PaPILO/LICENSE_papilo
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms(; experimental=true)))

filter!(platforms) do p
    libgfortran_version(p) >= v"4"
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("papilo", :papilo),
    ExecutableProduct("scip", :scip),
    LibraryProduct("libscip", :libscip),
]

dependencies = [
    Dependency(PackageSpec(name="bliss_jll", uuid="508c9074-7a14-5c94-9582-3d4bc1871065"), compat="=0.77.0"),
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.79.0"),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.8"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.1"),
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7"); compat="=300.1400.1302"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.10"),
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e"); compat="2021.8.0"),
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
