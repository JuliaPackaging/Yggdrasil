# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Perl"
version = v"5.34.1"

# Collection of sources required to build perl
# with a few extra modules for polymake
sources = [
    ArchiveSource("https://www.cpan.org/src/5.0/perl-$version.tar.gz", "357951a491b0ba1ce3611263922feec78ccd581dddc24a446b033e25acf242a1"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-4.03.tar.gz", "e41f8761a5e7b9b27af26fe5780d44550d7a6a66bf3078e337d676d07a699941"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/J/JO/JOSEPHW/XML-Writer-0.900.tar.gz", "73c8f5bd3ecf2b350f4adae6d6676d52e08ecc2d7df4a9f089fa68360d400d1f"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz", "5a645878dc570ac33661581fbb090ff24ebce17d43ea53fd22e105a856a47290"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.42.tar.gz", "3c5f1281da2666777af0f34de0289564e6faa823aea54f3945c74c98e95a5e73"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz", "4506c387043aa6a77b455f00f57409f3720aa7e553495ab2535263b4ed1ea12a"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz", "47e995859f8dd0413aa3f22d350c4a62da652e854267aa0586ae544ae2bae5ef"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz", "66cb355ba4ef47c10ca738bd35999723644386ac853abbeb5132841f5e8a2ad0"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/M/MA/MANWAR/SVG-2.86.tar.gz", "72c6eb6f86bb2c330280f9f3d342bb2673ad5da22d1f44fba3e04cfb5d30a67b"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/N/NE/NEILB/Exporter-Lite-0.08.tar.gz", "c05b3909af4cb86f36495e94a599d23ebab42be7a18efd0d141fc1586309dac2"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/P/PL/PLICEASE/File-Which-1.27.tar.gz", "3201f1a60e3f16484082e6045c896842261fc345de9fb2e620fd2a2c7af3a93a"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/G/GW/GWARD/Getopt-Tabular-0.3.tar.gz", "9bdf067633b5913127820f4e8035edc53d08372faace56ba6bfa00c968a25377"),
    ArchiveSource("https://cpan.metacpan.org/authors/id/A/AB/ABIGAIL/Regexp-Common-2017060201.tar.gz", "ee07853aee06f310e040b6bf1a0199a18d81896d3219b9b35c9630d0eb69089b"),
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
   [[ "$dir" == "config" ]] && continue;
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

# avoid touching the SIGFPE handler
atomic_patch -p1 ../patches/perlfpe.patch

if [[ $target != x86_64-linux* ]] && [[ $target != i686-linux* ]]; then
   # cross build with supplied config.sh
   # build native miniperl
   src=`pwd`
   mkdir host
   pushd host
   ../Configure -des \
                -Dusedevel \
                -Duserelocatableinc \
                -Dmksymlinks \
                -Dosname=linux \
                -Dcc=$CC_FOR_BUILD \
                -Dld=$LD_FOR_BUILD \
                -Dar=$AR_FOR_BUILD \
                -Dnm=$NM_FOR_BUILD \
                -Dlibs=-lm \
                -Duname=/bin/uname \
                -Dusenm=false
   make -j${nproc} miniperl
   make -j${nproc} generate_uudmap
   popd

   # copy and use prepared configure information
   novertarget=$(echo "${target}" | sed -E 's/[0-9.]+$//g')
   cp ../config/config-$novertarget.sh config.sh
   ./Configure -K -S
   extramakeargs=RUN_PERL=perl
else
   # native

   # config overrides
   # (not needed for cross-compilation where the correct value should be in config.sh)
   if [[ $target = *-gnu ]]; then
      cp ../config/config.arch.gnu config.arch
   fi
   if [[ $target = i686-linux-musl ]]; then
      extraflags="-fno-stack-protector"
   fi
   perlarch=$(echo $target | cut -d- -f2-)

   # setting PERL_FPU_INIT stops the perl init function from changing the SIGFPE handler
   # shortened libswanted to increase compatibility
   ./Configure -des -Dcc="$CC" \
               -Dprefix=$prefix \
               -Duserelocatableinc \
               -Duseshrplib \
               -Darchname=$perlarch \
               -Dsysroot=/opt/$target/$target/sys-root \
               -Dccflags="-DPERL_FPU_INIT -I${prefix}/include $extraflags" \
               -Dldflags="-L${libdir}" \
               -Dlddlflags="-shared -L${libdir}" \
               -Adefine:libswanted="pthread dl m util c"
fi

make -j${nproc} $extramakeargs
make install $extramakeargs

install_license Copying

# put a libperl directly in lib
cd $libdir
ln -s perl5/*/*/CORE/libperl.${dlext} libperl.${dlext}

# resolve case-ambiguity:
cd $libdir/perl5/5.*.*
mv Pod/* pod
rmdir Pod

# remove sysroot and target flags from stored compiler flags:
sed -i -e "s#--sysroot[ =][^ ']\+##g" \
       -e "s#-target[ =][^ ']\+##g" \
       ${prefix}/*/perl5/*/*/Config_heavy.pl
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p) &&
                         arch(p) != "armv6l",
                    supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("perl", :perl)
    LibraryProduct("libperl", :libperl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Readline_jll"; compat="8.1.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"7")

