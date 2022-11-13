using BinaryBuilder


name = "DynarePreprocessor"
version = v"6.0.2"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "00fd9dadb6dde5929c224c74e0a43715554a2c05"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
                  "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/preprocessor

# remove -lstdc++fs in Makefile.am
sed s/-lstdc++fs// -i src/Makefile.am

# Remove flex from RootFS to let use our flex from `flex_jll`
rm -f /usr/bin/flex

# Help FreeBSD find header files.  See
# https://github.com/JuliaPackaging/Yggdrasil/issues/3949
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
    LDFLAGS=-static-libgcc
fi
if [[ "${target}" == *-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
    #elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem` to work around the issue
    #     Undefined symbols for architecture x86_64:
    #       "__ZNKSt3__14__fs10filesystem4path10__filenameEv", referenced from:
    #           __ZNSt3__14__fs10filesystem4pathdVERKS2_ in dynare_preprocessor-ModelTree.o
    #           __ZNK11StaticModel15writeStaticFileERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEbbbS8_RKNS0_4__fs10filesystem4pathESD_b in dynare_preprocessor-StaticModel.o
    #           __ZNSt3__14__fs10filesystem4pathdVERKS2_ in dynare_preprocessor-StaticModel.o
    #           __ZNK12DynamicModel16writeDynamicFileERKNSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEbbbS8_RKNS0_4__fs10filesystem4pathESD_b in dynare_preprocessor-DynamicModel.o
    #           __ZNSt3__14__fs10filesystem4pathdVERKS2_ in dynare_preprocessor-DynamicModel.o
    #           __ZNSt3__14__fs10filesystem4pathdVERKS2_ in dynare_preprocessor-ModFile.o
    #           _main in dynare_preprocessor-DynareMain.o
    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    #    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

#atomic_patch -p1 "../patches/patches.patch"

autoreconf -si

update_configure_scripts
./configure --prefix=$prefix  --build=${MACHTYPE} --host=${target} --disable-doc
make -j${nproc}
make install
mkdir -p "${bindir}"
strip "src/dynare-preprocessor${exeext}"
cp "src/dynare-preprocessor${exeext}" "${bindir}"
install_license COPYING
"""

platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
