using BinaryBuilder, Pkg

name = "MUSCLE"
version = v"5.2"

sources = [
    GitSource("https://github.com/rcedgar/muscle.git",
                  "6c601163998616bb88991931e443c645858e162c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/muscle

# MUSCLE's Windows code paths are all guarded on _MSC_VER, so mingw falls into
# the POSIX branches instead.  Those don't build (no <sys/resource.h>, no
# sysconf()) and don't link (GetPhysMemBytes() is only defined for MSVC, Linux
# and Mach), and the ones that do compile give wrong answers on Windows.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-support.patch

cd src
EXTRA_LDFLAGS=""
if [[ "${target}" == *-mingw* ]]; then
    EXTRA_LDFLAGS="-lpsapi"   # GetProcessMemoryInfo, GlobalMemoryStatusEx
fi

# 32-bit targets (mingw, i686/armv6l/armv7l linux) default to a 32-bit off_t,
# and MUSCLE bails out with "File too big for 32-bit version" on inputs above
# 2GB when sizeof(off_t) == 4.  No-op on targets where off_t is already 64-bit.
make -j${nproc} CXX=c++ CXXFLAGS="-O3 -fopenmp -D_FILE_OFFSET_BITS=64" LDFLAGS2="${EXTRA_LDFLAGS}"
install -Dvm 755 "$(uname)/muscle" "${bindir}/muscle${exeext}"
install_license ${WORKSPACE}/srcdir/muscle/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(!Sys.isfreebsd, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("muscle", :muscle),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
