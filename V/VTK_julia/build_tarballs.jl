using BinaryBuilder, Pkg

name = "VTK_julia"
version = v"0.1.0"

sources = [
  GitSource("https://github.com/ffrancesco94/VTK_cxxwrap.git",
  "c4e77590ee854480821233058304bf30fbfb5f21"),  # v0.1.0+vtk9.7
]

script = raw"""
cd ${WORKSPACE}/srcdir/VTK_cxxwrap

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 -DJulia_PREFIX=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

platforms = [
  Platform("x86_64", "linux"; libc="glibc"),
  Platform("aarch64", "linux"; libc="glibc"),
  Platform("x86_64", "macos"),
  Platform("aarch64", "macos"),
]

products = [
  LibraryProduct("libvtk_julia", :libvtk_julia; dont_dlopen=true),
  FileProduct("VTKGen.jl", :VTKGen_exports)
]

dependencies = [
  BuildDependency("libjulia_jll"),
  Dependency("libcxxwrap_julia_jll"; compat="0.14.12"),
  Dependency("VTK_jll"; compat="9.7.1")
]

build_tarballs(
  ARGS, name, version, sources, script, platforms, products, dependencies;
  preferred_gcc_version=v"11",
  julia_compat="1.12"
)


