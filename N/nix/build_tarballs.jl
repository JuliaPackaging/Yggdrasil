using BinaryBuilder

name = "nix"
version = v"2.34.7"
sources = [
    GitSource(
        "https://github.com/NixOS/nix/",
        "2c6d06e9387cf58167cb5a7ab91cee7333d8d17c";
        unpack_target = "nix"
    ),
    #TODO replace with JLL dep
    GitSource(
        "https://github.com/BLAKE3-team/BLAKE3/",
        "93a431c78a52d7ccf0f366f106467f5070e6075e";
        unpack_target = "BLAKE3"
    ),
    GitSource(
        "https://github.com/anrieff/libcpuid",
        "2e4456ae0165db3155da2e8fba92afd5c090ca1b";
    ),
    GitSource(
        "https://github.com/ToruNiina/toml11",
        "be08ba2be2a964edcdb3d3e3ea8d100abc26f286";
    ),
    GitSource(
        "https://github.com/troglobit/editline",
        "ecabef273ebf4193c5d6aff196de1c204169bc52"
    )
]

script = raw"""
apk add pc:libsodium
apk add pc:libbrotlicommon
apk add perl-dev
apk add perl-dbi
apk add perl-dbd-sqlite
#TODO needed to test locally on darwin, remove before merge
# rm /usr/share/cmake/Modules/Compiler/._*
# rm /usr/lib/python3.9/site-packages/._*

cd ${WORKSPACE}/srcdir/editline
./autogen.sh
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make all -j${nproc}
make install

cd ${WORKSPACE}/srcdir/toml11
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DTOML11_BUILD_TESTS=OFF
cmake --build build --parallel ${nproc}
cmake --install build

cd ${WORKSPACE}/srcdir/libcpuid
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DLIBCPUID_ENABLE_TESTS=OFF
cmake --build build --parallel ${nproc}
cmake --install build

cd ${WORKSPACE}/srcdir/BLAKE3
cmake -S c -B c/build -DBUILD_SHARED_LIBS=true -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build c/build --parallel ${nproc}
cmake --install c/build

cd ${WORKSPACE}/srcdir/nix
install_license COPYING
#TODO fails because the linker detection logic forgets about overrides
# so far, the only option seems to be to patch the linker detection script
# in meson
meson setup build -Dunit-tests=false -Djson-schema-checks=false --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release
cd build
ninja -j${nproc}
ninja install
"""

platforms = supported_platforms()

products = Product[
    ExecutableProduct("nix", :nix),
]

dependencies = Dependency[
    Dependency("boost_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("LibArchive_jll"),
    Dependency("nlohmann_json_jll"),
    Dependency("LibCURL_jll"),
    Dependency("SQLite_jll"),
    Dependency("LibGit2_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"15")
