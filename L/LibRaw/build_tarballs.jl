# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibRaw"
version = v"0.20.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.libraw.org/data/LibRaw-0.20.2.tar.gz", "dc1b486c2003435733043e4e05273477326e51c3ea554c6864a4eafaff1004a6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd LibRaw-*
autoreconf --install
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-jasper
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mem_image", :mem_image),
    ExecutableProduct("postprocessing_benchmark", :postprocessing_benchmark),
    LibraryProduct("libraw", :libraw),
    ExecutableProduct("raw-identify", :raw_identify),
    ExecutableProduct("4channels", :_4channels),
    ExecutableProduct("half_mt", :half_mt),
    ExecutableProduct("multirender_test", :multirender_test),
    LibraryProduct("libraw_r", :libraw_r),
    ExecutableProduct("dcraw_emu", :dcraw_emu),
    ExecutableProduct("simple_dcraw", :simple_dcraw),
    ExecutableProduct("unprocessed_raw", :unprocessed_raw),
    ExecutableProduct("rawtextdump", :rawtextdump),
    ExecutableProduct("dcraw_half", :dcraw_half)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="JasPer_jll", uuid="f6ca3df5-1ae7-521a-b96b-cb83f57f3f1f"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="LittleCMS_jll", uuid="d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
