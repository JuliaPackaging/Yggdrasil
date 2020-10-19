# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Perl"
version = v"5.30.3"

# Collection of sources required to build perl
# with a few extra modules for polymake
sources = [
    ArchiveSource("https://www.cpan.org/src/5.0/perl-$version.tar.gz", "32e04c8bb7b1aecb2742a7f7ac0eabac100f38247352a73ad7fa104e39e7406f"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-4.02.tar.gz", "444a88755a89ffa2a5424ab4ed1d11dca61808ebef57e81243424619a9e8627c"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/J/JO/JOSEPHW/XML-Writer-0.625.tar.gz", "e080522c6ce050397af482665f3965a93c5d16f5e81d93f6e2fe98084ed15fbe"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz", "5a645878dc570ac33661581fbb090ff24ebce17d43ea53fd22e105a856a47290"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.36.tar.gz", "9a08f7a4013c9b865541c10dbba1210779eb9128b961250b746d26702bab6925"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz", "4506c387043aa6a77b455f00f57409f3720aa7e553495ab2535263b4ed1ea12a"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz", "47e995859f8dd0413aa3f22d350c4a62da652e854267aa0586ae544ae2bae5ef"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz", "66cb355ba4ef47c10ca738bd35999723644386ac853abbeb5132841f5e8a2ad0"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/M/MA/MANWAR/SVG-2.84.tar.gz", "ec3d6ddde7a46fa507eaa616b94d217296fdc0d8fbf88741367a9821206f28af"),
    DirectorySource("./bundled")
]

# Bash recipe for building
script = raw"""
perldir=`ls -1d perl-*`
cd $WORKSPACE/srcdir/
for dir in *;
do
   [[ "$dir" == "perl-"* ]] && continue;
   [[ "$dir" == "patches" ]] && continue;
   # build extra perl modules in-tree
   # the names of the extra modules also need to appear in the
   # config.sh for all cross-compilation architectures
   sed -i '1s/^/$ENV{PERL_CORE}=0;/' $dir/Makefile.PL
   mv $dir $perldir/cpan/${dir%-*};
done

cd $perldir/

# allow combining relocation with shared library
# add patch to find binary location from shared library
atomic_patch -p1 ../patches/allow-relocate.patch

# replace some library checks that wont work in the cross-compile environment
# with the required values
atomic_patch -p1 ../patches/cross-nolibchecks.patch

if [[ $target != x86_64-linux* ]] && [[ $target != i686-linux* ]]; then
   # cross build with supplied config.sh
   # build native miniperl
   src=`pwd`
   mkdir host
   pushd host
   ../Configure -des -Dusedevel -Duserelocatableinc -Dmksymlinks -Dosname=linux -Dcc=$CC_FOR_BUILD -Dld=$LD_FOR_BUILD -Dar=$AR_FOR_BUILD -Dnm=$NM_FOR_BUILD -Dlibs=-lm
   make -j${nproc} miniperl
   make -j${nproc} generate_uudmap
   cp -p miniperl $prefix/bin/miniperl-for-build
   popd

   # copy and use prepared configure information
   cp ../patches/config-$target.sh config.sh
   ./Configure -K -S
else
   # native

   # config overrides
   if [[ $target = *-gnu ]]; then
      # disable xlocale.h usage (which was removed in recent glibc)
      cp ../patches/config.arch.gnu config.arch
   fi

   ./Configure -des -Dcc="$CC" -Dprefix=$prefix -Duserelocatableinc -Dprocselfexe -Duseshrplib -Dsysroot=/opt/$target/$target/sys-root -Dccflags="-I${prefix}/include" -Dldflags="-L${libdir} -Wl,-rpath,${libdir}" -Dlddlflags="-shared -L${libdir} -Wl,-rpath,${libdir}"
fi

make -j${nproc} depend
make -j${nproc}

make install

# put a libperl directly in lib
cd $libdir
ln -s perl5/*/*/CORE/libperl.${dlext} libperl.${dlext}

# resolve case-ambiguity:
cd $libdir/perl5/5.*.*
mv Pod/* pod
rmdir Pod

# remove sysroot and target flags from stored compiler flags:
sed -i -e "s#--sysroot[ =]\S\+##g" \
       -e "s#-target[ =]\S\+##g" \
       ${prefix}/*/perl5/*/*/Config_heavy.pl

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "macos")
    Platform("x86_64", "linux"; libc="glibc")
    Platform("i686", "linux"; libc="glibc")
    Platform("x86_64", "linux"; libc="musl")
    Platform("i686", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("perl", :perl)
    LibraryProduct("libperl", :libperl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Readline_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
