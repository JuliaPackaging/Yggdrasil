# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "polymake"
version = v"4.2.0"

# Collection of sources required to build polymake
sources = [
    ArchiveSource("https://github.com/polymake/polymake/archive/V$(version.major).$(version.minor).tar.gz", "d308f551ef4c9f490a3a848d45a1ab41ae6461b1daf5be3deeaebad7df3816d4")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# the prepared config files for non-native architectures
# assume a fixed source directory
mv $WORKSPACE/srcdir/{polymake-*,polymake}
cd $WORKSPACE/srcdir/polymake

perl_version=5.30.3

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

if [[ $target == *darwin* ]]; then
  # we cannot run configure and instead provide config files
  mkdir -p build/Opt
  mkdir -p build/perlx/$perl_version/apple-darwin14
  cp ../config/config-$target.ninja build/config.ninja
  cp ../config/build-Opt-$target.ninja build/Opt/build.ninja
  cp ../config/targets.ninja build/targets.ninja
  ln -s ../config.ninja build/Opt/config.ninja
  cp ../config/perlx-config-$target.ninja build/perlx/$perl_version/apple-darwin14/config.ninja
  # for a modified pure perl JSON module and to make miniperl find the correct modules
  export PERL5LIB=$prefix/lib/perl5/$perl_version:$prefix/lib/perl5/$perl_version/darwin-2level:$WORKSPACE/srcdir/patches
  atomic_patch -p1 ../patches/polymake-cross.patch
  atomic_patch -p1 ../patches/polymake-cross-build.patch
else
  ./configure CFLAGS="-Wno-error" CC="$CC" CXX="$CXX" \
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
              --without-native
fi

ninja -v -C build/Opt -j${nproc}

ninja -v -C build/Opt install

# undo patch needed for building
if [[ $target == *darwin* ]]; then
  atomic_patch -R -p1 ../patches/polymake-cross-build.patch
fi
install -m 444 -D support/*.pl $prefix/share/polymake/support/

# replace miniperl
sed -i -e "s/miniperl-for-build/perl/" ${libdir}/polymake/config.ninja ${bindir}/polymake*
# replace binary path with env
sed -i -e "s#$bindir/perl#/usr/bin/env perl#g" ${libdir}/polymake/config.ninja ${bindir}/polymake*
# remove target and sysroot
sed -i -e "s#--sysroot[ =]\S\+##g" ${libdir}/polymake/config.ninja
sed -i -e "s#-target[ =]\S\+##g" ${libdir}/polymake/config.ninja

# copy of build config that has prefix as a variable
sed -e "s#${prefix}#\${prefix}#g" ${libdir}/polymake/config.ninja > ${libdir}/polymake/config-reloc.ninja

# cleanup symlink tree
rm -rf ${prefix}/deps

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
 MacOS(:x86_64, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
 Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolymake", :libpolymake; dont_dlopen=true)
    LibraryProduct("libpolymake-apps-rt", :libpolymake_apps_rt; dont_dlopen=true)
    ExecutableProduct("polymake", :polymake)
    ExecutableProduct("polymake-config", Symbol("polymake_config"))
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll")
    Dependency("FLINT_jll")
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
    Dependency("PPL_jll")
    Dependency(PackageSpec(name="Perl_jll", uuid="83958c19-0796-5285-893e-a1267f8ec499", version=v"5.30.3"))
    Dependency("bliss_jll")
    Dependency("boost_jll")
    Dependency("cddlib_jll")
    Dependency("lrslib_jll")
    Dependency("normaliz_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", init_block="""

   mutable_artifacts_toml = joinpath(dirname(@__DIR__), "MutableArtifacts.toml")
   polymake_tree = "polymake_tree"
   polymake_tree_hash = artifact_hash(polymake_tree, mutable_artifacts_toml)

   # create a directory tree for polymake with links to dependencies
   # looking similiar to the tree in the build environment
   # for compiling wrappers at run-time
   polymake_tree_hash = create_artifact() do art_dir
      mkpath(joinpath(art_dir,"deps"))
      for dep in [FLINT_jll, GMP_jll, MPFR_jll, PPL_jll, Perl_jll, bliss_jll, boost_jll, cddlib_jll, lrslib_jll, normaliz_jll]
         symlink(dep.artifact_dir, joinpath(art_dir,"deps","\$dep"))
      end
      for dir in readdir(polymake_jll.artifact_dir)
         symlink(joinpath(polymake_jll.artifact_dir,dir), joinpath(art_dir,dir))
      end
   end
   bind_artifact!(mutable_artifacts_toml,
      polymake_tree,
      polymake_tree_hash;
      force=true
   )

   # Point polymake to our custom tree
   ENV["POLYMAKE_DEPS_TREE"] = artifact_path(polymake_tree_hash)
""")

