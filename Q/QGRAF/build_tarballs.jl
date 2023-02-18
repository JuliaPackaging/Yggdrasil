# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QGRAF"
version = v"3.6.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://anonymous:anonymous@qgraf.tecnico.ulisboa.pt/v3.6/qgraf-$(version).tgz", "648cc82bf3327a4c36d36847d3921fcfa5d7f73c1646241760db030abdc86c29")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cat sha256sums | while read line; do
    name=$(echo $line | awk '{print $2}')
    expect_sum=$(echo $line | awk '{print $1}')
    check_sum=$(sha256sum $name | awk '{print $1}')
    if [ $check_sum != $expect_sum ]; then
        echo "sha256sum checks failed!"
        echo "Expect $line but got $(sha256sum $name)!"
        exit 1
    fi
done

mkdir fmodules
mkdir -p "${bindir}"
${FC} -o "${bindir}/qgraf${exeext}" -Os -J fmodules qgraf-3.6.5.f08

mkdir -p ${prefix}/share/QGRAF
mkdir -p ${prefix}/share/licenses/QGRAF

mv qgraf${exeext} ${prefix}/bin/
mv array.sty form.sty phi3 qcd qed qedx qgraf.dat sha256sums sum.sty ${prefix}/share/QGRAF/
head -93 qgraf-3.6.5.f08 > ${prefix}/share/licenses/QGRAF/license
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("qgraf", :qgraf, "bin"),
    FileProduct("share/QGRAF/array.sty", :qgraf_array_sty),
    FileProduct("share/QGRAF/form.sty", :qgraf_form_sty),
    FileProduct("share/QGRAF/sum.sty", :qgraf_sum_sty),
    FileProduct("share/QGRAF/phi3", :qgraf_phi3),
    FileProduct("share/QGRAF/qcd", :qgraf_qcd),
    FileProduct("share/QGRAF/qed", :qgraf_qed),
    FileProduct("share/QGRAF/qedx", :qgraf_qedx),
    FileProduct("share/QGRAF/qgraf.dat", :qgraf_dat)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
