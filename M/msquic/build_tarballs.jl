# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msquic"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/msquic.git", "7e8f28fec1a0d9b93f274026a277a6d9b0cf7c7d"),
    ArchiveSource("http://lttng.org/files/lttng-ust/lttng-ust-2.12.2.tar.bz2", "bcd0f064b6ca88c72d84e760eac3472ae5c828411c634435922bee9fce359fc7"),
    ArchiveSource("http://lttng.org/files/lttng-tools/lttng-tools-2.12.4.tar.bz2", "d729f8c2373a41194f171aeb0da0a9bb35ac181f31afa7e260786d19a500dea1"),
    ArchiveSource("http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.18.tar.gz", "5159bc03a20b28ce363aa96765f37df99ea4d8850b1ece17d1e6ad5c24fdc5d1"),
    ArchiveSource("http://xmlsoft.org/sources/libxml2-sources-2.9.10.tar.gz", "9c332062611b88e773d81c070364525c3f0cefa0ecaac902dcedb72e6e44c978"),
    ArchiveSource("https://lttng.org/files/urcu/userspace-rcu-latest-0.13.tar.bz2", "cbb20dbe1a892c2a4d8898bac4316176e585392693d498766ccbbc68cf20ba20"),
    ArchiveSource("https://github.com/numactl/numactl/releases/download/v2.0.14/numactl-2.0.14.tar.gz", "826bd148c1b6231e1284e42a4db510207747484b112aee25ed6b1078756bcff6"),
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1k.tar.gz", "892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"),
    ArchiveSource("https://github.com/Kitware/CMake/releases/download/v3.21.0/cmake-3.21.0.tar.gz", "4a42d56449a51f4d3809ab4d3b61fd4a96a469e56266e896ce1009b5768bd2ab"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd popt-1.18/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
cd ../libxml2-2.9.10/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --without-python
make
make install
cd ../userspace-rcu-0.13.0/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
cd ../numactl-2.0.14/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
sed -e s/-ffast-math//g -i Makefile
make
make install
cd ../lttng-ust-2.12.2/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages --disable-examples
make
make install
cd ../lttng-tools-2.12.4/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages
make
make install
cd ../openssl-1.1.1k/
./config --prefix=${prefix}
make
make install
cd ../cmake-3.21.0/
./configure --prefix=${prefix}
make
make install
cd ../msquic/
git submodule update --init --recursive
mkdir build && cd build
/workspace/destdir/bin/cmake -G 'Unix Makefiles' ..
/workspace/destdir/bin/cmake --build .
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liburcu-mb", :userspace_mb),
    LibraryProduct("liblttng-ust-fork", :lttng_ust_fork),
    LibraryProduct("liblttng-ust", :lttng_ust),
    LibraryProduct("libpopt", :popt),
    LibraryProduct("liburcu-qsbr", :userspace_qsbr),
    LibraryProduct("liblttng-ust-fd", :lttng_ust_fd),
    LibraryProduct("liblttng-ust-ctl", :lttng_ust_ctl),
    LibraryProduct("liblttng-ust-dl", :lttng_ust_dl),
    LibraryProduct("liburcu-bp", :userspace_bp),
    LibraryProduct("liburcu-memb", :userspace_memb),
    LibraryProduct("liburcu", :userspace),
    LibraryProduct("libnuma", :numactl),
    LibraryProduct("liburcu-cds", :userspace_cds),
    LibraryProduct("liblttng-ust-libc-wrapper", :lttng_ust_libc),
    LibraryProduct("libxml2", :xml2),
    LibraryProduct("liburcu-common", :userspace_common),
    LibraryProduct("liblttng-ust-tracepoint", :lttng_usr_tracepoint),
    LibraryProduct("liblttng-ctl", :lttng_ctl),
    LibraryProduct("liblttng-ust-pthread-wrapper", :lttng_ust_pthread),
    LibraryProduct("liburcu-signal", :userspace_signal)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
