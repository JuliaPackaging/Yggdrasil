# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Hwloc"
version = v"2.8.0"

# Collection of sources required to build hwloc
sources = [
    ArchiveSource("https://download.open-mpi.org/release/hwloc/v$(version.major).$(version.minor)/hwloc-$(version).tar.bz2",
                  "348a72fcd48c32a823ee1da149ae992203e7ad033549e64aed6ea6eeb01f42c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hwloc-*
# CUDA (always on)
cuda_dir="${prefix}/cuda"
if [[ ${nbits} == 64 ]]; then
    cuda_lib_dir="${cuda_dir}/lib64"
else
    cuda_lib_dir="${cuda_dir}/lib"
fi
export "CPPFLAGS=${CPPFLAGS} -I${cuda_dir}/include"
export "LDFLAGS=${LDFLAGS} -L${cuda_lib_dir} -Wl,-rpath,${cuda_lib_dir} -L${cuda_lib_dir}/stubs -Wl,-rpath,${cuda_lib_dir}/stubs"
# RSMI (requires C++11, requires CUDA)
if [[ ${bb_full_target} =~ cxx11 ]]; then
    rsmi_dir="${prefix}/rocm_smi"
    export "CPPFLAGS=${CPPFLAGS} -I${rsmi_dir}/include"
    export "CFLAGS=${CFLAGS} -std=c11"
    export "CXXFLAGS=${CXXFLAGS} -std=c++11"
    export "LDFLAGS=${LDFLAGS} -L${rsmi_dir}/lib -Wl,-rpath,${rsmi_dir}/lib"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# We make a difference between C++03 and C++11 targets because RSMI requires C++11, but we want to support C++03 as well
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    #TODO "; dont_dlopen=gpu"
    LibraryProduct("libhwloc", :libhwloc),
    ExecutableProduct("lstopo-no-graphics", :lstopo_no_graphics),
]

# Dependencies that must be installed before this package can be built
# CUDA 11 requires a newer libc (v2.17) than ours
const cuda_version = "10.2.89"
dependencies = [
    Dependency(PackageSpec(name="CUDA_jll"); compat=cuda_version),
    Dependency(PackageSpec(name="ROCmOpenCLRuntime_jll")),
    Dependency(PackageSpec(name="XML2_jll")),
    Dependency(PackageSpec(name="Xorg_libpciaccess_jll")),
    Dependency(PackageSpec(name="rocm_smi_lib_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
