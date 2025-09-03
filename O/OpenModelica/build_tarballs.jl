using BinaryBuilder, Pkg

name = "OpenModelica"
version = v"1.25.1"

sources = [
   GitSource("https://github.com/OpenModelica/OpenModelica.git",
             "66757f39f530bc032d5c1a71c105bd568207444a"),
   DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OpenModelica*

# Build writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

cp ../patches/git-config ./.git/config
git submodule update --force --init --recursive

apk del cmake
apk --update --no-chown add openjdk17-jdk

cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBLA_VENDOR=OpenBLAS \
      -DOM_ENABLE_GUI_CLIENTS=OFF \
      -DOM_OMSHELL_ENABLE_TERMINAL=ON \
      -DOM_OMC_ENABLE_IPOPT=OFF \
      -DHAVE_MMAP_DEV_ZERO=0 \
      -DHAVE_MMAP_DEV_ZERO_EXITCODE__TRYRUN_OUTPUT=""

cmake --build build_cmake --parallel ${nprocs} --target install

install_license OSMC-License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686",   "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("omc", :omc),
#    ExecutableProduct("OMShell-terminal", :OMShell_terminal),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    HostBuildDependency("flex_jll"),
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
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
               julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"9")
