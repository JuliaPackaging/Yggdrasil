using BinaryBuilder, Pkg

name = "HSARuntime"
version = v"7.0.01120251130"

sources = [
    FileSource("https://rocm.nightlies.amd.com/v2/gfx1150/rocm_sdk_core-7.11.0a20251130-py3-none-linux_x86_64.whl",
               "01250b8baa92d45f0af2a32456db8e2d6d42f575afb781ef1b8fee47fe644ed2"),
    FileSource("https://raw.githubusercontent.com/ROCm/rocm-systems/refs/heads/develop/projects/rocr-runtime/LICENSE.txt",
               "ffa5a77ce21419e276bd9068faec94333128e49e1c95426d9c1d35435e8fe835"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

unzip rocm_sdk_core-*.whl

# Extract the specific libraries
install -Dvm 755 _rocm_sdk_core/lib/libhsa-runtime64.so.1 ${libdir}/libhsa-runtime64.so.1
install -Dvm 755 _rocm_sdk_core/lib/librocprofiler-register.so.0 ${libdir}/librocprofiler-register.so.0

# Copy the rocm_sysdeps folder
cp -rv _rocm_sdk_core/lib/rocm_sysdeps ${libdir}/

install_license LICENSE.txt

# Create soname symlinks
cd ${libdir}
ln -s libhsa-runtime64.so.1 libhsa-runtime64.so
ln -s librocprofiler-register.so.0 librocprofiler-register.so
"""

# ROCm only supports x86_64 Linux with glibc
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
]

products = [
    LibraryProduct("libhsa-runtime64", :libhsa_runtime64),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
