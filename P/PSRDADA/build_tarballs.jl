# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PSRDADA"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/code-snapshots/git/p/ps/psrdada/code.git/psrdada-code-62fc33a8730ffa2611d955e732ce7250a5a055b5.zip", "dfe8e8a9b66766a4c84836de26150dfc9bc204bc596b0c5788905e26dda2f1db")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/psrdada*
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libpsrdada", :libpsrdada),
    ExecutableProduct("dada_dbevent", :dada_dbevent),
    ExecutableProduct("dada_dbxferinfo", :dada_dbxferinfo),
    ExecutableProduct("dada_install_header", :dada_install_header),
    ExecutableProduct("dada_dbnum", :dada_dbnum),
    ExecutableProduct("dada_numdb", :dada_numdb),
    ExecutableProduct("dada_write_test", :dada_write_test),
    ExecutableProduct("dada_dbmetric", :dada_dbmetric),
    ExecutableProduct("dada_diskdb", :dada_diskdb),
    ExecutableProduct("dspsr_start_time", :dspsr_start_time),
    ExecutableProduct("dada_db", :dada_db),
    ExecutableProduct("dada_header", :dada_header),
    ExecutableProduct("dada_mem_test", :dada_mem_test),
    ExecutableProduct("dada_nicdb", :dada_nicdb),
    ExecutableProduct("dada_dbmeminfo", :dada_dbmeminfo),
    ExecutableProduct("slow_rm", :slow_rm),
    ExecutableProduct("dada_dbnull", :dada_dbnull),
    ExecutableProduct("dada_dbmonitor", :dada_dbmonitor),
    ExecutableProduct("load_test", :load_test),
    ExecutableProduct("dada_dbrecover", :dada_dbrecover),
    ExecutableProduct("dada_dbcopydb", :dada_dbcopydb),
    ExecutableProduct("dada_zerodb", :dada_zerodb),
    ExecutableProduct("dada_dbmergedb", :dada_dbmergedb),
    ExecutableProduct("dada_pwc_command", :dada_pwc_command),
    ExecutableProduct("test_disk_perf", :test_disk_perf),
    ExecutableProduct("dada_dbdisk", :dada_dbdisk),
    ExecutableProduct("dada_dboverflow", :dada_dboverflow),
    ExecutableProduct("dada_dbscrubber", :dada_dbscrubber),
    ExecutableProduct("dada_dbNdb", :dada_dbNdb),
    ExecutableProduct("dada_dbnic", :dada_dbnic),
    ExecutableProduct("dada_edit", :dada_edit),
    ExecutableProduct("dada_junkdb", :dada_junkdb),
    ExecutableProduct("dada_pwc_demo", :dada_pwc_demo),
    ExecutableProduct("dada_write_block_test", :dada_write_block_test)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2")
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
