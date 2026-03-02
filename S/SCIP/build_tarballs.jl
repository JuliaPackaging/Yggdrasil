# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "SCIP"

upstream_version = v"10.0.0"
version = VersionNumber(upstream_version.major * 100, upstream_version.minor * 100, upstream_version.patch * 100 + 2)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/scipopt/scip/releases/download/v$(upstream_version)/scipoptsuite-$(upstream_version).tgz",
        "44877ca34f3d5f7e09dfed4738cf52046a20950417060f844f1ca37a77a60d1c"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# needed for now
# clock_gettime requires linking to librt -lrt with old glibc
# remove when CMake accounts for this
if [[ "${target}" == *86*-linux-gnu ]]; then
   export LDFLAGS="-lrt"
elif [[ "${target}" == *-mingw* ]]; then
   # this is required to link to bliss on mingw
   export LDFLAGS=-L${libdir}
fi

cd scipoptsuite*

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DPAPILO=0\
  -DZIMPL=OFF\
  -DGCG=0\
  -DUG=0\
  -DAMPL=0\
  -DBOOST=ON\
  -DMPFR=ON\
  -DSYM=snauty\
  -DTPI=tny\
  -DIPOPT_DIR=${prefix} \
  -DIPOPT_LIBRARIES=${libdir} \
  ..
make -j${nproc}
make install

mkdir -p ${prefix}/share/licenses/SCIP
# Move all licenses installed by SCIP to the correct folder for the JLL
mv -v ${prefix}/share/licenses/scip ${prefix}/share/licenses/SCIP
mv -v ${prefix}/share/licenses/soplex ${prefix}/share/licenses/SCIP
"""

# This requires macOS 10.13
sources, script = require_macos_sdk("10.13", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
filter!(platforms) do p
    !(Sys.isfreebsd(p) && arch(p) == "aarch64") && !occursin("riscv", arch(p))
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libscip", :libscip),
    ExecutableProduct("scip", :scipexe),
    LibraryProduct("libsoplexshared", :libsoplex),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.87.0"),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.9"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.2.1"),
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7"); compat="300.1400.1900"),
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"); compat="4.2.0"),
    Dependency(PackageSpec(name="Readline_jll", uuid="05236dd9-4125-5232-aa7c-9ec0c9b2c25a")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"12", julia_compat="1.9")
