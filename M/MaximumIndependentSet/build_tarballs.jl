using BinaryBuilder

name = "MaximumIndependentSet"
version = v"0.1"
sources = [
    GitSource("https://github.com/claud10cv/MaximumIndependentSet.git", "3b37c113bd2e1b93bf38808f036632a731f0349b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/MaximumIndependentSet
make -j${nproc}
make install
"""

platforms = supported_platforms()
filter!(t -> os(t) in ["linux"], platforms)
filter!(t -> arch(t) == "x86_64", platforms)
filter!(t -> isnothing(libc(t)) ||  libc(t) == "glibc", platforms)

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
               preferred_gcc_version=v"11")
