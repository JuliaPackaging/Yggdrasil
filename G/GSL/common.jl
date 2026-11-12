using BinaryBuilder

name = "GSL"

gsl_sources(version_string, sha256) = [
    ArchiveSource("https://mirrors.kernel.org/gnu/gsl/gsl-$(version_string).tar.gz", sha256),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/gsl-*/
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # aclocal.m4 has some lines where it expects `MACOSX_DEPLOYMENT_TARGET` to be up to
    # version 10.  Let's pretend to be 10.16, as many tools do to make old build systems
    # happy.
    export MACOSX_DEPLOYMENT_TARGET="10.16"
fi

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libgslcblas", :libgslcblas),
    LibraryProduct("libgsl", :libgsl),
    ExecutableProduct("gsl-histogram", :gsl_histogram),
    ExecutableProduct("gsl-randist", :gsl_randist),
]

dependencies = Dependency[
]
