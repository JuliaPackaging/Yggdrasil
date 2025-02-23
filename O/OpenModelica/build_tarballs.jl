using BinaryBuilder, Pkg

name = "OpenModelica"
version = v"1.24.4"
git_sha = "1fcd964f50824f82fd36d536804b0d80234131c9"

sources = [
   GitSource("https://github.com/OpenModelica/OpenModelica.git",
             git_sha),
   DirectorySource("./bundled"),	     
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenModelica*
cp ../patches/git-config ./.git/config
git submodule update --force --init --recursive

apk --update --no-chown add openjdk17-jdk

cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBLA_VENDOR=libopenblas \
      -DBLAS_LIBRARIES="-L${libdir} -lopenblas" \
      -DLAPACK_LIBRARIES="-L${libdir} -lopenblas" \
      -DOM_ENABLE_GUI_CLIENTS=OFF \
      -DOM_OMSHELL_ENABLE_TERMINAL=ON \
      -DOM_OMC_ENABLE_IPOPT=OFF \
      -DHAVE_MMAP_DEV_ZERO=0 \
      -DHAVE_MMAP_DEV_ZERO_EXITCODE__TRYRUN_OUTPUT=""

cmake --build build_cmake --parallel ${nprocs} --target install

install_license OSMC-License.txt
x
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "windows"; cxxstring_abi="cxx11"),
    Platform("aarch64", "macos"; cxxstring_abi="cxx11"),
]
#platforms = expand_cxxstring_abis(supported_platforms())

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
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("util_linux_jll"),
    Dependency("boost_jll"; compat="=1.76.0"),
    Dependency("LLVMOpenMP_jll"),
    Dependency("OpenCL_jll"),
    Dependency("Expat_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Gettext_jll"),
    Dependency("Ncurses_jll"),
    Dependency("Readline_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", clang_use_lld=false, preferred_gcc_version=v"10")
