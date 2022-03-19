using BinaryBuilder


name = "DynarePreprocessor"
version = v"4.8.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "a8fce06dc46ca09329e6899e1fde47f2cd81809b"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
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
if [[ "${target}" == *-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
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
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

atomic_patch -p1 "../patches/patches.patch"

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

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
