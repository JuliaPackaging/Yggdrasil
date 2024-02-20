using BinaryBuilder, Pkg

name = "LinearSampling"
version = v"1.0.0"

sources = [
    ArchiveSource("https://github.com/LinearFold/LinearSampling/archive/refs/tags/v$(version).tar.gz",
                  "f81d475259551349967f8d349f0d7312667c32f759ce32c09b7ecb0d6c2e0ea8"),
]

script = raw"""
cd $WORKSPACE/srcdir/LinearSampling-*/

make -j${nproc} CC=${CXX}
mkdir -p ${bindir}
for b in bin/*; do
    install -Dvm 755 "${b}" "${bindir}/$(basename "${b}")${exeext}"
done

install_license LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("exact_linearsampling_lazysaving", :exact_linearsampling_lazysaving),
    ExecutableProduct("exact_linearsampling_nonsaving", :exact_linearsampling_nonsaving),
    ExecutableProduct("linearsampling_lazysaving", :linearsampling_lazysaving),
    ExecutableProduct("linearsampling_nonsaving", :linearsampling_nonsaving),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
