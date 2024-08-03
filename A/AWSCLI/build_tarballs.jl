using BinaryBuilder

name = "AWSCLI"
version = v"2.17.22"

sources = [
    GitSource("https://github.com/aws/aws-cli.git",
              "18d64caf588186c396dd58ff2346a8ca9657fdcb"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/aws-cli

export CMAKE_INSTALL_PREFIX="${prefix}"
export CMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"

PYTHON="$(which python3)" ./configure --prefix=${prefix} --with-download-deps --with-install-type=portable-exe
make -j${nproc}
make install

install_license ./LICENSE.txt
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("aws", :awscli),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6")
