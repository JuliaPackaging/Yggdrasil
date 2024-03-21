using BinaryBuilder

name = "MaximumIndependentSet"
version = v"0.1.1"
sources = [
    GitSource("https://github.com/claud10cv/MaximumIndependentSet.git", "fe2e7ccc79f4de024e798c4daf9dcb3b8e99b906"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/MaximumIndependentSet
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()
#filter!(t -> os(t) in ["linux"], platforms)
#filter!(t -> arch(t) == "x86_64", platforms)
#filter!(t -> isnothing(libc(t)) || libc(t) == "glibc", platforms)

products = [
    LibraryProduct("libmis", :libmis),
]

dependencies = [
]

build_tarballs(ARGS,
               name,
               version,
               sources,
               script,
               platforms,
               products,
               dependencies,
               julia_compat = "1.9";
               preferred_gcc_version=v"9")
