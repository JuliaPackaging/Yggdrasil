using BinaryBuilder, Pkg

name = "COMPSs"
version = v"3.3.1"

sources = [
    # GitSource("https://github.com/bsc-wdc/compss.git", "567b41a02c0a4d090f72413ca0270d708ea087b2")
    ArchiveSource("http://compss.bsc.es/repo/sc/stable/COMPSs_$(version).tar.gz", "aa4f1f0cb0efef70f8b22f9444102ca786d98c2c022aecce8c9a30bf3421f775"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
# cd $WORKSPACE/srcdir/compss
# git submodule update --init --recursive --depth=1
cd $WORKSPACE/srcdir/COMPSs

# apply patches
atomic_patch -p1 $WORKSPACE/srcdir/patches/001-bindings-common-cross-compile.patch

# install dependencies
apk add openjdk8 maven openssh-server
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk/

# ./builders/buildlocal --no-monitor --no-pycompss --no-tracing --no-kafka --no-jacoco --no-dlb --cli --no-pycompss-compile --no-python-style --skip-tests $prefix
export COMPSs_HOME=$prefix/COMPSs
mkdir -p $COMPSs_HOME

# deploy COMPSs
cp -r * "${COMPSs_HOME}"
sed -i -e 's#/opt/COMPSs/#'"${COMPSs_HOME}"'#g' "${COMPSs_HOME}"/Runtime/configuration/xml/projects/default_project.xml
rm -rf "${COMPSs_HOME}"/Bindings/* "${COMPSs_HOME}"/Dependencies/*

# install C bindings
cd $WORKSPACE/srcdir/COMPSs/Bindings/bindings-common/
./install_common "${COMPSs_HOME}"/Bindings/bindings-common

cd $WORKSPACE/srcdir/COMPSs/Bindings/c/
./install "${COMPSs_HOME}"/Bindings/c true
"""

platforms = supported_platforms()
filter!(==(64) ∘ wordsize, platforms)
filter!(x -> Sys.isapple(x) || Sys.islinux(x), platforms)
platforms = expand_cxxstring_abis(platforms)

products = Product[]

dependencies = Dependency[
    Dependency("Libtool_jll"),
    Dependency("XML2_jll"),
    Dependency("boost_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
