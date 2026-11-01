# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PTI"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/pti-gpu.git",
              "fdc44f65ccfc4c75f951a8f01b1ef9326223aaaf"; tag="pti-$(version)"),
    # dependencies PTI otherwise downloads at configure time, at the versions it pins.
    # spdlog and fmt are linked statically: spdlog_jll is too old (PTI needs 1.17).
    # Only ittapi's headers are used, including the private `ittnotify_config.h` that
    # ittapi_jll does not ship; PTI implements the ITT collector itself.
    GitSource("https://github.com/fmtlib/fmt.git",
              "407c905e45ad75fc29bf0f9bb7c5c2fd3475976f"; tag="12.1.0"),
    GitSource("https://github.com/gabime/spdlog.git",
              "79524ddd08a4ec981b7fea76afd08ee05f83755d"; tag="v1.17.0"),
    GitSource("https://github.com/intel/ittapi.git",
              "2369c7eb60bbe5db9f0996b0366c68c4c0950100"; tag="v3.26.8"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pti-gpu/sdk
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DPTI_BUILD_SAMPLES=OFF \
      -DPTI_BUILD_TESTING=OFF \
      -DPTI_BUILD_URGEMM=OFF \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
      -DFETCHCONTENT_SOURCE_DIR_FMT=${WORKSPACE}/srcdir/fmt \
      -DFETCHCONTENT_SOURCE_DIR_SPDLOG=${WORKSPACE}/srcdir/spdlog \
      -DFETCHCONTENT_SOURCE_DIR_ITTAPI=${WORKSPACE}/srcdir/ittapi
cmake --build build --parallel ${nproc}
cmake --install build
install_license ${WORKSPACE}/srcdir/pti-gpu/LICENSE
install -Dvm 644 ${WORKSPACE}/srcdir/fmt/LICENSE ${prefix}/share/licenses/PTI/LICENSE.fmt
install -Dvm 644 ${WORKSPACE}/srcdir/spdlog/LICENSE ${prefix}/share/licenses/PTI/LICENSE.spdlog
for license in ${WORKSPACE}/srcdir/ittapi/LICENSES/*; do
    install -Dvm 644 ${license} ${prefix}/share/licenses/PTI/ittapi-$(basename ${license})
done

# PTI calls the buffer callbacks from its own threads; see the source file
${CC} -O2 -shared -fPIC -o ${libdir}/libpti_buffers.${dlext} \
      ${WORKSPACE}/srcdir/pti_buffers.c -lpthread
"""

platforms = supported_platforms()
# PTI supports Linux and Windows, but the Level Zero loader it links is only built for
# x86_64 Linux
filter!(p -> Sys.islinux(p) && arch(p) == "x86_64", platforms)
# its only user, oneAPI.jl, needs Intel's driver, which is only built for glibc
filter!(p -> libc(p) == "glibc", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built. These are only loaded when
# profiling: libpti_view starts a thread once used, and libpti hooks into Level Zero.
products = [
    LibraryProduct("libpti_view", :libpti_view; dont_dlopen=true),
    LibraryProduct("libpti", :libpti, ["lib/pti"]; dont_dlopen=true),
    LibraryProduct("libpti_buffers", :libpti_buffers; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; compat="1"),
    Dependency("oneAPI_Level_Zero_Loader_jll"; compat="1.32"),
    BuildDependency("oneAPI_Level_Zero_Headers_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.10")
