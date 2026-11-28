using BinaryBuilder

name = "rapidyaml"
# Match the release pinned by the PALSParserCpp consumer.
version = v"0.15.0"
sources = [
    GitSource("https://github.com/biojppm/rapidyaml.git",
              "e80ab40670a16fd70a3972cb77e59f280670f581"; tag="v$(version)"),
    GitSource("https://github.com/biojppm/c4core.git", "f46d6abb17bff2f597b1fcc6243d1daf95f41b74"),
    GitSource("https://github.com/biojppm/cmake.git", "9b4161420e7af50796bb2c984bbfc7b451cbb668"),
    GitSource("https://github.com/biojppm/debugbreak.git", "328e4abca3384cbd0a69e70f263cc7b2794bff09"),
    GitSource("https://github.com/fastfloat/fast_float.git", "eb9ab42c0aa86d3cc41871ba7306527d95077b3b"),
]

script = raw"""
# GitSource does not populate the nested submodules recorded by rapidyaml.
cp -av ${WORKSPACE}/srcdir/c4core/. ${WORKSPACE}/srcdir/rapidyaml/ext/c4core/
cp -av ${WORKSPACE}/srcdir/cmake/. ${WORKSPACE}/srcdir/rapidyaml/ext/c4core/cmake/
cp -av ${WORKSPACE}/srcdir/debugbreak/. ${WORKSPACE}/srcdir/rapidyaml/ext/c4core/src/c4/ext/debugbreak/
cp -av ${WORKSPACE}/srcdir/fast_float/. ${WORKSPACE}/srcdir/rapidyaml/ext/c4core/src/c4/ext/fast_float/

cd ${WORKSPACE}/srcdir/rapidyaml
cmake -S . -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DRYML_BUILD_TESTS=OFF \
    -DRYML_BUILD_BENCHMARKS=OFF \
    -DRYML_BUILD_TOOLS=OFF \
    -DRYML_INSTALL=ON
cmake --build build --parallel ${nproc}
cmake --install build

# Upstream incorporates c4core into ryml; retain the bundled notices.
install_license LICENSE.txt
install -Dvm 644 ext/c4core/LICENSE.txt ${prefix}/share/licenses/rapidyaml/c4core-LICENSE.txt
install -Dvm 644 ext/c4core/LICENSE-BOOST.txt ${prefix}/share/licenses/rapidyaml/c4core-LICENSE-BOOST.txt
install -Dvm 644 ext/c4core/src/c4/ext/debugbreak/COPYING ${prefix}/share/licenses/rapidyaml/debugbreak-COPYING
install -Dvm 644 ext/c4core/src/c4/ext/fast_float/LICENSE-MIT ${prefix}/share/licenses/rapidyaml/fast_float-LICENSE-MIT
install -Dvm 644 ext/c4core/src/c4/ext/fast_float/LICENSE-APACHE ${prefix}/share/licenses/rapidyaml/fast_float-LICENSE-APACHE
install -Dvm 644 ext/c4core/src/c4/ext/fast_float/LICENSE-BOOST ${prefix}/share/licenses/rapidyaml/fast_float-LICENSE-BOOST
"""

platforms = expand_cxxstring_abis(supported_platforms())
products = [LibraryProduct(["libryml", "ryml"], :libryml)]
dependencies = [Dependency("CompilerSupportLibraries_jll"; compat="1")]

# c4core uses posix_memalign; GCC >= 6 avoids its musl allocation issue.
# Julia compatibility matches the PALSParserJ consumer's minimum version.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"6")
