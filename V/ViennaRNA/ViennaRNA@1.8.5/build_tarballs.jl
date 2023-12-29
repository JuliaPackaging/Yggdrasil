using BinaryBuilder, Pkg

name = "ViennaRNA"
version = v"1.8.5"
# released in 2011, ViennaRNA-1.8.5 was the last of the 1.x.y versions

# url = "https://www.tbi.univie.ac.at/RNA/"
# description = "Library and programs for the prediction and comparison of RNA secondary structures"

# Build errors
# - Kinfold causes build errors on FreeBSD and MacOS (clang?)
# - RNAforester probably has build problems on Windows like in
#   ViennaRNA-2.x.y, disabled for now

sources = [
    ArchiveSource("https://www.tbi.univie.ac.at/RNA/download/sourcecode/" *
                  "$(version.major)_$(version.minor)_x/ViennaRNA-$(version).tar.gz",
                  "f4e2d94beaf77165e8321758e4ab0ad1c5d49879cefa12e48b07d09ed2d0ecf9"),
    DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir/ViennaRNA*/

# fixes linking errors
atomic_patch -p1 ../patches/fix-ViennaRNA-1.8.5-compile.patch

update_configure_scripts --reconf

./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --without-perl \
    --with-cluster \
    --without-kinfold --without-forester

make -j${nproc}
make install

# create and install a shared library libRNA
"${CC}" -g -O2 \
    -shared -o "${libdir}/libRNA.${dlext}" \
    -Wl,$(flagon --whole-archive) ./lib/libRNA.a -Wl,$(flagon --no-whole-archive)

# install licenses
# cp RNAforester/COPYING COPYING-RNAforester
# install_license COPYING-RNAforester
install_license COPYING
"""

platforms = supported_platforms()
# platforms = expand_cxxstring_abis(platforms) # for RNAforester

products = [
    ExecutableProduct("AnalyseDists", :AnalyseDists),
    ExecutableProduct("AnalyseSeqs", :AnalyseSeqs),
    # ExecutableProduct("Kinfold", :Kinfold),
    ExecutableProduct("RNAaliduplex", :RNAaliduplex),
    ExecutableProduct("RNAalifold", :RNAalifold),
    ExecutableProduct("RNAcofold", :RNAcofold),
    ExecutableProduct("RNAdistance", :RNAdistance),
    ExecutableProduct("RNAduplex", :RNAduplex),
    ExecutableProduct("RNAeval", :RNAeval),
    ExecutableProduct("RNAfold", :RNAfold),
    # ExecutableProduct("RNAforester", :RNAforester),
    ExecutableProduct("RNAheat", :RNAheat),
    ExecutableProduct("RNAinverse", :RNAinverse),
    ExecutableProduct("RNALfold", :RNALfold),
    ExecutableProduct("RNApaln", :RNApaln),
    ExecutableProduct("RNApdist", :RNApdist),
    ExecutableProduct("RNAplfold", :RNAplfold),
    ExecutableProduct("RNAplot", :RNAplot),
    ExecutableProduct("RNAsubopt", :RNAsubopt),
    ExecutableProduct("RNAup", :RNAup),
    LibraryProduct("libRNA", :libRNA),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"4")
