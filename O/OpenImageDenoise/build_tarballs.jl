# Note: run `julia build_tarballs.jl --help` for a usage message.
#
# Each platform has its own upstream archive, so this file calls `build_tarballs`
# once per platform.  Pass at most ONE triplet on the command line: a
# comma-separated list in ARGS[1] replaces the `platforms` argument of every
# `build_tarballs` call (see BinaryBuilder's AutoBuild.jl), which would build
# each target from the wrong platform's sources.  Yggdrasil's CI already invokes
# builders one triplet at a time.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "OpenImageDenoise"
version = v"2.5.1"

# Repackaged upstream: a source build needs ISPC, DPC++, hipcc and Metal.
const url = "https://github.com/RenderKit/oidn/releases/download/v$(version)"

platform_sources = Dict(
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource("$(url)/oidn-$(version).x86_64.linux.tar.gz",
                      "743c3e2aff8c220d5d70fe6cb970fb3d36f2702d2693c61d1d148e404cf37cd6"),
    ],
    Platform("x86_64", "windows") => [
        ArchiveSource("$(url)/oidn-$(version).x64.windows.zip",
                      "f11f91bc072a5e3a564515724cb72ab8fcfbc445c84a84c197ff9b16cc01396f"),
    ],
    Platform("x86_64", "macos") => [
        ArchiveSource("$(url)/oidn-$(version).x86_64.macos.tar.gz",
                      "a4341639005a33ce0d944bd7c771ce34de1465be7eb3189b7c3b5b0064429832"),
    ],
    Platform("aarch64", "macos") => [
        ArchiveSource("$(url)/oidn-$(version).arm64.macos.tar.gz",
                      "98e0aca8e7ab69e9f4f0191582a500fd8b0d9085d68662f18ab6469e934a6efd"),
    ],
)

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/oidn-*/
install_license doc/LICENSE.txt doc/third-party-programs*.txt

mkdir -p "${includedir}" "${libdir}" "${bindir}" "${prefix}/lib"
cp -a include/OpenImageDenoise "${includedir}/"
cp -a lib/cmake "${prefix}/lib/"

# TBB and the SYCL runtime stay bundled: upstream links them by soname.
if [[ "${target}" == *-mingw* ]]; then
    cp -a bin/*.dll "${bindir}/"
    cp -a bin/oidn*.exe "${bindir}/"
    # Import libraries: lib/cmake points IMPORTED_IMPLIB at these.
    # NOTE: ${libdir} is ${prefix}/bin on mingw, so target ${prefix}/lib explicitly.
    cp -a lib/*.lib "${prefix}/lib/"
    # The upstream zip carries no exec bit, and the auditor only chmods DLLs.
    chmod +x "${bindir}"/oidn*.exe
else
    cp -a lib/*.${dlext}* "${libdir}/"
    cp -a bin/oidn* "${bindir}/"
    chmod +x "${bindir}"/oidn*
fi
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libOpenImageDenoise", "OpenImageDenoise"], :libOpenImageDenoise),
    ExecutableProduct("oidnDenoise", :oidnDenoise),
    ExecutableProduct("oidnBenchmark", :oidnBenchmark),
]

# Dependencies that must be installed before this package can be built.
# The archives otherwise bundle TBB and the SYCL/Level Zero runtime.
#
# Hwloc satisfies libhwloc.so.15 in the bundled libtbbbind, which TBB dlopen's
# to pin workers to the CPU topology.  Without it TBB still runs, just unpinned.
dependencies = Dependency[
    Dependency("Hwloc_jll"),
]

# Remaining auditor complaints are expected and not fixable here:
#  * libgcc_s.so.1 "could not be resolved" -- CompilerSupportLibraries_jll does
#    NOT help, as it has no artifact for x86_64-linux-gnu-libgfortran3-cxx03,
#    the ABI variant the auditor picks, so nothing lands in the prefix to map
#    onto.  It resolves at runtime regardless: Julia ships lib/julia/libgcc_s.so.1
#    and libjulia links it, so the soname is already in the global namespace.
#  * libcuda.so.1, libze_loader.so.1, libamdhip64.so.7 and the macOS Metal
#    frameworks are drivers and must not be shipped.

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

filter!(platform_sources) do (platform, sources)
    should_build_platform(triplet(platform))
end

for (idx, (platform, sources)) in enumerate(platform_sources)
    # Use "--register" only on the last invocation of build_tarballs
    args = idx < length(platform_sources) ? non_reg_ARGS : ARGS
    build_tarballs(args, name, version, sources, script, [platform], products,
                   dependencies; julia_compat="1.6")
end
