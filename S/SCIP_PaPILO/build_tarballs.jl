# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP_PaPILO"

upstream_version = v"9.2.1"
version = VersionNumber(upstream_version.major * 100, upstream_version.minor * 100, upstream_version.patch * 100)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://scipopt.org/download/release/scipoptsuite-$(upstream_version).tgz",
        "41b71a57af773403e9a6724f78c37d8396ac4b6b270a9bbf3716d67f1af12edf"
    ),
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
        "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4"
    ),
    DirectorySource("./bundled/")
]

# Bash recipe for building across all platforms
script = raw"""
# This requires macOS 10.13
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.13
    popd
fi

cd scipoptsuite*

# for soplex threadlocal
export CXXFLAGS="-DTHREADLOCAL=''"

# Enable large file support on mingw
if [[ "${target}" == *-mingw* ]]; then
    export CXXFLAGS="-Wa,-mbig-obj"
fi

# Patch to fix linking with gfortran's library on mingw
# https://github.com/JuliaPackaging/Yggdrasil/pull/8224#issuecomment-2034941690
atomic_patch -p0 $WORKSPACE/srcdir/patches/papilo_cmake.patch

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
  -DSYM=snauty\
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

# Filter out the aarch64 FreeBSD and RISC-V architectures because oneTBB isn't available there yet.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> !(Sys.islinux(p) && arch(p) == "riscv64"), platforms)

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
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7"); compat="=300.1400.1400"),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"); compat="0.3.10"),
    Dependency(PackageSpec(name="oneTBB_jll", uuid="1317d2d5-d96f-522e-a858-c73665f53c3e"); compat="2021.9.0"),
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
    preferred_gcc_version=v"8",
    julia_compat="1.6",
    clang_use_lld=false,
)
