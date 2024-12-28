using BinaryBuilder

name = "IntelOpenMP"
version = v"2024.2.1"

sources = [
    # Main OpenMP files
    FileSource("https://files.pythonhosted.org/packages/c6/02/e5c7e10a4bedeec4eb0f61fa8fe951e2febf6ba9ae08f806ada5f2f35ada/intel_openmp-2024.2.1-py2.py3-none-win32.whl",
               "3dbed102d8a79f091fc3364ff4b6268e1b2904d80a58926987fc6006171c18cd"; filename="intel_openmp-i686-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/c8/6c/9334569937fd3c6ec93f9fe3da268db38f5113673d568854fa18a20f36ec/intel_openmp-2024.2.1-py2.py3-none-win_amd64.whl",
               "b1fb47eefc6cbc2358216684dd87bd2315464e6d29ac84f9313819fe1528d969"; filename="intel_openmp-x86_64-w64-mingw32.whl"),
    FileSource("https://files.pythonhosted.org/packages/ed/a6/92e7356c981fcfefa4fbd132791d28656ec02ff62124d283b10219999d5d/intel_openmp-2024.2.1-py2.py3-none-manylinux1_i686.whl",
               "ba6de86c394331719c795e743bcff3bbc10c3a16a0d3622d90819593de4c7e34"; filename="intel_openmp-i686-linux-gnu.whl"),
    FileSource("https://files.pythonhosted.org/packages/78/2d/64570ae938a8ee2337ed8ba28ae1d85d3555ee6e5faadabea9e8b43a900d/intel_openmp-2024.2.1-py2.py3-none-manylinux1_x86_64.whl",
               "21892ea07a9c6e164707d2b44e6f396f9f2ab6cc7e108755011fad59b596182a"; filename="intel_openmp-x86_64-linux-gnu.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d intel_openmp-$target intel_openmp-$target.whl

if [[ ${target} == *i686-w64-mingw* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/bin32/* -t "${libdir}"

    # These import libraries go inside the actual lib folder, not the bin folder with the DLLs
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/lib32/libiomp5md.lib -t "${prefix}/lib/"
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/lib32/libiompstubs5md.lib -t "${prefix}/lib/"
fi
if [[ ${target} == *x86_64-w64-mingw* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/Library/bin/* -t "${libdir}"

    # These import libraries go inside the actual lib folder, not the bin folder with the DLLs
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/Library/lib/libiomp5md.lib -t "${prefix}/lib/"
    install -Dv intel_openmp-${target}/intel_openmp-*.data/data/Library/lib/libiompstubs5md.lib -t "${prefix}/lib/"
fi
if [[ ${target} == *i686-linux-gnu* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/lib32/*.${dlext} -t "${libdir}"
fi
if [[ ${target} == *x86_64-linux-gnu* ]]; then
    install -Dvm 755 intel_openmp-${target}/intel_openmp-*.data/data/lib/*.${dlext} -t "${libdir}"
fi
install_license intel_openmp-${target}/intel_openmp-*.dist-info/LICENSE.txt
install_license intel_openmp-${target}/intel_openmp-*.data/data/share/doc/compiler/licensing/openmp/third-party-programs.txt
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["libiomp5", "libiomp5md"], :libiomp),
]

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
