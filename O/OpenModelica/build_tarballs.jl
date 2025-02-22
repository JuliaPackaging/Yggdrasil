using BinaryBuilder, Pkg

name = "OpenModelica"
version = v"1.24.3"

sources = [
   GitSource("https://github.com/OpenModelica/OpenModelica.git",
             "fcf63c83c7e8d66b7c5da922376ec54a5f1faad7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mv OpenModelica OM-ignore
git clone https://github.com/OpenModelica/OpenModelica.git
cd OpenModelica
git checkout 904c4c783a5fa6eb9e99e4a98bdb0cca1d619303
git submodule update --force --init --recursive

apk --update --no-chown add openjdk17-jdk

cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBLA_VENDOR=libopenblas \
      -DBLAS_LIBRARIES="-L${libdir} -lopenblas" \
      -DLAPACK_LIBRARIES="-L${libdir} -lopenblas" \
      -DOM_ENABLE_GUI_CLIENTS=OFF \
      -DOM_OMC_ENABLE_IPOPT=OFF \
      -DHAVE_MMAP_DEV_ZERO=0 \
      -DHAVE_MMAP_DEV_ZERO_EXITCODE__TRYRUN_OUTPUT=""

cmake --build build_cmake --parallel ${nprocs} --target install

install_license OSMC-License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("omc", :omc),
#    ExecutableProduct("OMShell-terminal", :OMShell_terminal),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("flex_jll"),
    Dependency("LibCURL_jll"),
    Dependency("util_linux_jll"),
    Dependency("boost_jll"; compat="=1.76.0"),
    Dependency("LLVMOpenMP_jll"),
    Dependency("OpenCL_jll"),
    Dependency("Expat_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Gettext_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", clang_use_lld=false, preferred_gcc_version=v"10")
