# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

name = "polymake"
upstream_version = v"4.5"
version_offset = v"0.1.0"
version = VersionNumber(upstream_version.major*100+version_offset.major,
                        upstream_version.minor*100+version_offset.minor,
                        version_offset.patch)

# Collection of sources required to build polymake
sources = [
    ArchiveSource("https://github.com/polymake/polymake/archive/V$(upstream_version.major).$(upstream_version.minor).tar.gz",
                  "77e98f1d41ed7d0eee8e983814bcb3f1a1b2b6100420ccd432bd2e796f0bc48a")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# the prepared config files for non-native architectures
# assume a fixed source directory
mv $WORKSPACE/srcdir/{polymake-*,polymake}
cd $WORKSPACE/srcdir/polymake

# to be able to generate a similiar dependency tree at runtime
# we prepare a symlink tree for all dependencies
mkdir -p ${prefix}/deps
for dir in FLINT GMP MPFR PPL Perl bliss boost cddlib lrslib normaliz; do
   ln -s .. ${prefix}/deps/${dir}_jll
done

# adjust for hardcoded /workspace dirs
atomic_patch -p1 ../patches/relocatable.patch

# to unbreak ctrl+c in julia
atomic_patch -p1 ../patches/sigint.patch

# work around sigchld-handler conflicts with other libraries
atomic_patch -p1 ../patches/sigchld.patch

if [[ $target != x86_64-linux* ]] && [[ $target != i686-linux* ]]; then
  perl_arch=$(grep "perlxpath=" ../config/build-Opt-$target.ninja | cut -d / -f 3)
  perl_version=$(grep "perlxpath=" ../config/build-Opt-$target.ninja | cut -d / -f 2)
  # we cannot run configure and instead provide config files
  mkdir -p build/Opt
  mkdir -p build/perlx/$perl_version/$perl_arch
  cp ../config/config-$target.ninja build/config.ninja
  cp ../config/build-Opt-$target.ninja build/Opt/build.ninja
  cp ../config/targets.ninja build/targets.ninja
  ln -s ../config.ninja build/Opt/config.ninja
  cp ../config/perlx-config-$target.ninja build/perlx/$perl_version/$perl_arch/config.ninja

  atomic_patch -p1 ../patches/polymake-cross.patch
else
  unset LD_LIBRARY_PATH
  $bindir/perl \
  support/configure.pl CFLAGS="-Wno-error" CC="$CC" CXX="$CXX" \
              PERL=${prefix}/deps/Perl_jll/bin/perl \
              LDFLAGS="$LDFLAGS -L${prefix}/deps/Perl_jll/lib -Wl,-rpath,${prefix}/deps/Perl_jll/lib" \
              --prefix=${prefix} \
              --with-flint=${prefix}/deps/FLINT_jll \
              --with-gmp=${prefix}/deps/GMP_jll \
              --with-mpfr=${prefix}/deps/MPFR_jll \
              --with-ppl=${prefix}/deps/PPL_jll \
              --with-bliss=${prefix}/deps/bliss_jll \
              --with-boost=${prefix}/deps/boost_jll \
              --with-cdd=${prefix}/deps/cddlib_jll \
              --with-lrs=${prefix}/deps/lrslib_jll \
              --with-libnormaliz=${prefix}/deps/normaliz_jll \
              --without-singular \
              --without-native \
              --without-prereq
fi

# C++ templates to need quite a lot of memory during compilation...
(( nproc=1+nproc/3 ))

ninja -v -C build/Opt -j${nproc}

ninja -v -C build/Opt install

# remove target and sysroot
sed -i -e "s#--sysroot[ =]\S\+##g" ${libdir}/polymake/config.ninja
sed -i -e "s#-target[ =]\S\+##g" ${libdir}/polymake/config.ninja

# copy of build config that has prefix as a variable
sed -e "s#${prefix}#\${prefix}#g" ${libdir}/polymake/config.ninja > ${libdir}/polymake/config-reloc.ninja

# adjust perl path
sed -i -e "s|^#!.*perl|#!/usr/bin/env perl|g" ${bindir}/polymake*
sed -i -e "s#^PERL = .*#PERL = /usr/bin/env perl#g" ${libdir}/polymake/config*

# cleanup symlink tree
rm -rf ${prefix}/deps

# copy julia script to generate dependency-tree at load time
cp ../patches/generate_deps_tree.jl $prefix/share/polymake

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) &&
                         arch(p) != "armv6l",
                    supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolymake", :libpolymake)
    LibraryProduct("libpolymake-apps-rt", :libpolymake_apps_rt)
    ExecutableProduct("polymake", :polymake)
    ExecutableProduct("polymake-config", Symbol("polymake_config"))
    FileProduct("share/polymake/generate_deps_tree.jl", :generate_deps_tree)
]



# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Perl_jll", version=v"5.34.0")),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("FLINT_jll", compat = "~200.800.401"),
    Dependency("PPL_jll", compat = "~1.2.1"),
    Dependency("Perl_jll", compat = "=5.34.0"),
    Dependency("bliss_jll", compat = "~0.73.1"),
    Dependency("boost_jll", compat = "=1.76.0"),
    Dependency("cddlib_jll", compat = "~0.94.13"),
    Dependency("lrslib_jll", compat = "~0.3.3"),
    Dependency("normaliz_jll", compat = "~300.900.100"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"7")
