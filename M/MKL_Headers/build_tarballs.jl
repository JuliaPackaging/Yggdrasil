# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MKL_Headers"
version = v"2025.2.0"

# Collection of sources required to complete build
sources = [
    # Source files from PyPi mkl-include package: https://pypi.org/project/mkl-include/#files
    FileSource("https://files.pythonhosted.org/packages/06/87/3eee37bf95c6b820b6394ad98e50132798514ecda1b2584c71c2c96b973c/mkl_include-2025.2.0-py2.py3-none-win_amd64.whl",
               "d20305b4adfa36407a808ec6a16dc5d6da6f8b9cb4a96bdcc0e0ab3239c43816"; filename="mkl_include-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/11/58/6f583b3bac7d3952a89a00ab34e61baa17f6d6de3454a8005958289bef22/mkl_include-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "691ceaccf6d960e19d47304d24ca2ee4e807810077e93c1c86c2e32cd6223012"; filename="mkl_include-x86_64-linux-gnu.whl"),
    # Source files from PyPi mkl-devel package: https://pypi.org/project/mkl-devel/#files
    FileSource("https://files.pythonhosted.org/packages/86/60/f979218ad807331524f3cd88c05b603d9ea5a685cffa513304bee8ae012b/mkl_devel-2025.2.0-py2.py3-none-win_amd64.whl",
               "305745583d7b08d2f8b8b37d20e6fa4b4325627a5989625c74aaaf651b10e9da"; filename="mkl_devel-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/bf/0c/6f5acc9d11087f4f6c739d019181028910555eb48af353e285ba80cd5d40/mkl_devel-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "990fb052a566c24042892b5585f32d27b8338ed801c86f7db2d40edc56dc8906"; filename="mkl_devel-x86_64-linux-gnu.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d mkl_include-$target mkl_include-$target.whl
unzip -d mkl_devel-$target mkl_devel-$target.whl

if [[ $target == *-mingw* ]]; then
    rsync -av mkl_include-${target}/mkl_include-*.data/data/Library/include/ ${includedir}
else
    rsync -av mkl_include-${target}/mkl_include-*.data/data/include/ ${includedir}
fi
install_license mkl_include-${target}/mkl_include-*.dist-info/LICENSE.txt

mkdir -p ${libdir}
if [[ $target == *-mingw* ]]; then
    # These toolchain files must still go inside the lib folder, not the ${libdir} folder
    rsync -av mkl_devel-${target}/mkl_devel-*.data/data/Library/lib/ ${prefix}/lib
else
    rsync -av mkl_devel-${target}/mkl_devel-*.data/data/lib/ ${libdir}
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
