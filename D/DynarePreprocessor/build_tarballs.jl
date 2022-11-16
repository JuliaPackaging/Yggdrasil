using BinaryBuilder

name = "DynarePreprocessor"
version = v"6.1.0"
sources = [
    GitSource("https://git.dynare.org/Dynare/preprocessor.git", "4807a6c8806b650094f8a1fc8bc7435e94d38305"),
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

if [[ "${target}" == *-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX11.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/libxml2/libxml
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=11.1
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

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("dynare-preprocessor", :dynare_preprocessor),
]

dependencies = [
    BuildDependency("boost_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"13")
