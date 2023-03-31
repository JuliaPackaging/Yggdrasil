# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kira"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/kira-pyred/kira.git", "8001d64f23406d6c4cb06578b89011c1a0c04c65"),
    ArchiveSource("https://www.ginac.de/ginac-1.8.6.tar.bz2", "00b320b1116cae5b7b43364dbffb7912471d171f484d82764605d715858d975b"),
    GitSource("https://gitlab.com/firefly-library/firefly.git", "f0b0b316790fbe23b88dd7b759220944bc77302d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ${WORKSPACE}/srcdir/ginac-*.*.*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
cd ${WORKSPACE}/srcdir/firefly/
mkdir $WORKSPACE/srcdir/FireFly-build
cd $WORKSPACE/srcdir/FireFly-build/
cmake -DWITH_FLINT=true     -DWITH_JEMALLOC=true     -DWITH_MPI=true     -DCMAKE_INSTALL_PREFIX=$prefix     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}     -DCMAKE_BUILD_TYPE=Release     ${WORKSPACE}/srcdir/firefly
cmake --build . -j${nproc}
cmake --build . -t install
mkdir ${WORKSPACE}/srcdir/Kira-build
cd ${WORKSPACE}/srcdir/Kira-build/
cd ${WORKSPACE}/srcdir/kira/
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
cd ${WORKSPACE}/srcdir/Kira-build/
ninja -j${nproc}
ls
cd src/
ls
cd kira/
ls
cd 
cd ${WORKSPACE}/srcdir/Kira-build/src/kira/kira.p/
ls
cd ..
ls
cd ..
ls
cd /workspace/destdir/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/local/lib/
cd /workspace/destdir/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/
cd /opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/
ls
cd lib
ls
ls
cd ..
ls
cd usr/local
ls
cd l
cd lib
ls
ls
cd ${WORKSPACE}/srcdir/
ls
cd Kira-build/
ls
cat build.ninja 
ls
cd ..
ls
cd kira/
ls
meson -Dfirefly=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
rm -rf ${WORKSPACE}/srcdir/Kira-build/*
meson -Dfirefly=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
ninja -C ${WORKSPACE}/srcdir/Kira-build/ -j${nproc}
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
ls
echo ${MESON_TARGET_TOOLCHAIN} 
cat ${MESON_TARGET_TOOLCHAIN} 
echo $LD_LIBRARY_PATH 
echo $LD_FOR_BUILD 
echo $LD_BUILD 
ls
cd ${WORKSPACE}/destdir
ls
cd lib
ls
ls
cd ..
ls
cd ..
ls
cd srcdir/
ls
cd Kira-build/
ls
less compile_commands.json 
ls
cd meson-info/
ls
cd ..
ls
cd meson-logs/
ls
cd ..
ls
cd meson-private/
ls
cd ..
ls
rm -rf ./*
ls
cd ..
ls
cd kira/
ls
meson --version
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
meson install
cd ${WORKSPACE}/srcdir/Kira-build/
meson install
cd /workspace/destdir/opt/
cd ${WORKSPACE}/srcdir/kira/
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --lib=${libdir} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --libdir=${libdir} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
rm -rf ${WORKSPACE}/srcdir/Kira-build/*
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --libdir=${libdir} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
cd ${WORKSPACE}/srcdir/Kira-build/
meson install
cat ${MESON_TARGET_TOOLCHAIN} 
echo ${WORKSPACE}/
echo ${WORKSPACE}
pkg-config libz
pkg-config zlib
pkg-config gmp
pkg-config --help
pkg-config --libs
pkg-config --exists
pkg-config --libs gmp
ls
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/Kira-build/
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/kira/ ${WORKSPACE}/srcdir/Kira-build/
meson setup --wipe
meson setup --wipe ./
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/kira/ ${WORKSPACE}/srcdir/Kira-build/
rm -rf ./*
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/kira/ ${WORKSPACE}/srcdir/Kira-build/
pkg-config --libs zlib
pkg-config --libs yaml-cpp
pkg-config --libs mpi
pkg-config --libs mpicxx
pkg-config --libs ginac
pkg-config --libs gmp
pkg-config --libs pthread
pkg-config --libs libmpi
pkg-config --libs mpicxx
pkg-config --libs mpich
echo $LD_LIBRARY_PATH 
ls
cat build.ninja 
sed -i "s/\/workspace\/destdir\/opt/\/opt/g" build.ninja 
mv build.ninja ../build.ninja.bak
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/kira/ ${WORKSPACE}/srcdir/Kira-build/
rm -rf ./*
meson setup -Dfirefly=true -Dflint=true -Dmpi=true -Djemalloc=true --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release ${WORKSPACE}/srcdir/kira/ ${WORKSPACE}/srcdir/Kira-build/
diff build.ninja ../build.ninja.bak 
sed -i "s/\/workspace\/destdir\/opt/\/opt/g" build.ninja 
meson install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("kira", :kira)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CLN_jll", uuid="b3974076-79ef-58d3-b5c7-5ef926e97925"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
    Dependency(PackageSpec(name="yaml_cpp_jll", uuid="01fea8cc-7d33-533a-824e-56a766f4ffe8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
