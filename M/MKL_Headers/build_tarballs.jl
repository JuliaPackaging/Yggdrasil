# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2025.0.1"

# Collection of sources required to complete build
sources = [
    FileSource("https://files.pythonhosted.org/packages/cd/b7/092df7c41f57b3a41bb60392081564da0ea64ae300128fa9d44dd7acd84b/mkl_include-2025.0.1-py2.py3-none-win_amd64.whl",
               "1149c1b34bc41166c0bb09c103e42ae251f0a9d190b886a99124b70632b3bc8d"; filename="mkl_include-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/7b/42/74f3ed839c59e7bf3992804ce172590b4acac01dac4157f81daeb7774202/mkl_include-2025.0.1-py2.py3-none-manylinux_2_28_x86_64.whl",
               "a70b90ce07f7a970a6fc8b324e416e0e978edec751b2d2e1b52d511f886fe506"; filename="mkl_include-x86_64-linux-gnu.whl"),
    FileSource("https://files.pythonhosted.org/packages/1f/b1/03a2388889052dd018cebf8b915599015161519c6af89e42e4a31a62e2f0/mkl_devel-2025.0.1-py2.py3-none-win_amd64.whl",
               "fc62df9c689722dadf282af6380538063dbd4fd3d328aa3c60eb72a521d06789"; filename="mkl_devel-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/fd/e1/b13109f2d31fc6b1e753d0746317a62a119292ec127e196b409ad420587b/mkl_devel-2025.0.1-py2.py3-none-manylinux_2_28_x86_64.whl",
               "18662a91ce12613622b7e002b7f5dcb790bf22bba83cef80179b9d2d3458ed2d"; filename="mkl_devel-x86_64-linux-gnu.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d mkl_include-$target mkl_include-$target.whl
unzip -d mkl_devel-$target mkl_devel-$target.whl

cd $WORKSPACE/srcdir/mkl_include-$target
if [[ $target == *-mingw* ]]; then
    rsync -av mkl_include-${target}/mkl_include-2025.0.1.data/data/Library/include/ ${includedir}
else
    rsync -av mkl_include-${target}/mkl_include-2025.0.1.data/data/include/ ${includedir}
fi
install_license mkl_include-${target}/mkl_include-2025.0.1.dist-info/LICENSE.txt

cd $WORKSPACE/srcdir/mkl_devel-$target
mkdir -p ${libdir}
if [[ $target == *-mingw* ]]; then
    # These toolchain files must still go inside the lib folder, not the ${libdir} folder
    rsync -av mkl_devel-${target}/mkl_devel-2025.0.1.data/data/Library/lib/ $WORKSPACE/destdir/lib
else
    rsync -av mkl_devel-${target}/mkl_devel-2025.0.1.data/data/lib/ ${libdir}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    FileProduct("include/mkl.h", :include_mkl_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
