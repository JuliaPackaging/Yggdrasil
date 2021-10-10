# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NITRO"
version = v"2.10.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mdaus/nitro/archive/refs/tags/NITRO-$(version).tar.gz", "26d7abb14bfbe6dbcb273f961b639e2bed68aa890f25cab82d9eed2b882fd1a3")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/nitro*
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DENABLE_PYTHON=OFF

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("ACCHZB", :ACCHZB, "share/nitf/plugins"),
    LibraryProduct("ACCPOB", :ACCPOB, "share/nitf/plugins"),
    LibraryProduct("ACCVTB", :ACCVTB, "share/nitf/plugins"),
    LibraryProduct("ACFTA", :ACFTA, "share/nitf/plugins"),
    LibraryProduct("ACFTB", :ACFTB, "share/nitf/plugins"),
    LibraryProduct("AIMIDA", :AIMIDA, "share/nitf/plugins"),
    LibraryProduct("AIMIDB", :AIMIDB, "share/nitf/plugins"),
    LibraryProduct("AIPBCA", :AIPBCA, "share/nitf/plugins"),
    LibraryProduct("ASTORA", :ASTORA, "share/nitf/plugins"),
    LibraryProduct("BANDSA", :BANDSA, "share/nitf/plugins"),
    LibraryProduct("BANDSB", :BANDSB, "share/nitf/plugins"),
    LibraryProduct("BCKGDA", :BCKGDA, "share/nitf/plugins"),
    LibraryProduct("BLOCKA", :BLOCKA, "share/nitf/plugins"),
    LibraryProduct("BNDPLB", :BNDPLB, "share/nitf/plugins"),
    LibraryProduct("CCINFA", :CCINFA, "share/nitf/plugins"),
    LibraryProduct("CLCTNA", :CLCTNA, "share/nitf/plugins"),
    LibraryProduct("CLCTNB", :CLCTNB, "share/nitf/plugins"),
    LibraryProduct("CMETAA", :CMETAA, "share/nitf/plugins"),
    LibraryProduct("CSCCGA", :CSCCGA, "share/nitf/plugins"),
    LibraryProduct("CSCRNA", :CSCRNA, "share/nitf/plugins"),
    LibraryProduct("CSDIDA", :CSDIDA, "share/nitf/plugins"),
    LibraryProduct("CSEPHA", :CSEPHA, "share/nitf/plugins"),
    LibraryProduct("CSEXRA", :CSEXRA, "share/nitf/plugins"),
    LibraryProduct("CSEXRB", :CSEXRB, "share/nitf/plugins"),
    LibraryProduct("CSPROA", :CSPROA, "share/nitf/plugins"),
    LibraryProduct("CSSFAA", :CSSFAA, "share/nitf/plugins"),
    LibraryProduct("CSSHPA", :CSSHPA, "share/nitf/plugins"),
    LibraryProduct("ENGRDA", :ENGRDA, "share/nitf/plugins"),
    LibraryProduct("EXOPTA", :EXOPTA, "share/nitf/plugins"),
    LibraryProduct("EXPLTA", :EXPLTA, "share/nitf/plugins"),
    LibraryProduct("EXPLTB", :EXPLTB, "share/nitf/plugins"),
    LibraryProduct("GEOLOB", :GEOLOB, "share/nitf/plugins"),
    LibraryProduct("GEOPSB", :GEOPSB, "share/nitf/plugins"),
    LibraryProduct("GRDPSB", :GRDPSB, "share/nitf/plugins"),
    LibraryProduct("HISTOA", :HISTOA, "share/nitf/plugins"),
    LibraryProduct("ICHIPB", :ICHIPB, "share/nitf/plugins"),
    LibraryProduct("IMASDA", :IMASDA, "share/nitf/plugins"),
    LibraryProduct("IMGDTA", :IMGDTA, "share/nitf/plugins"),
    LibraryProduct("IMRFCA", :IMRFCA, "share/nitf/plugins"),
    LibraryProduct("IOMAPA", :IOMAPA, "share/nitf/plugins"),
    LibraryProduct("J2KLRA", :J2KLRA, "share/nitf/plugins"),
    LibraryProduct("JITCID", :JITCID, "share/nitf/plugins"),
    LibraryProduct("MAPLOB", :MAPLOB, "share/nitf/plugins"),
    LibraryProduct("MATESA", :MATESA, "share/nitf/plugins"),
    LibraryProduct("MENSRA", :MENSRA, "share/nitf/plugins"),
    LibraryProduct("MENSRB", :MENSRB, "share/nitf/plugins"),
    LibraryProduct("MPDSRA", :MPDSRA, "share/nitf/plugins"),
    LibraryProduct("MSDIRA", :MSDIRA, "share/nitf/plugins"),
    LibraryProduct("MSTGTA", :MSTGTA, "share/nitf/plugins"),
    LibraryProduct("MTIRPA", :MTIRPA, "share/nitf/plugins"),
    LibraryProduct("MTIRPB", :MTIRPB, "share/nitf/plugins"),
    LibraryProduct("NBLOCA", :NBLOCA, "share/nitf/plugins"),
    LibraryProduct("OBJCTA", :OBJCTA, "share/nitf/plugins"),
    LibraryProduct("OFFSET", :OFFSET, "share/nitf/plugins"),
    LibraryProduct("PATCHA", :PATCHA, "share/nitf/plugins"),
    LibraryProduct("PATCHB", :PATCHB, "share/nitf/plugins"),
    LibraryProduct("PIAEQA", :PIAEQA, "share/nitf/plugins"),
    LibraryProduct("PIAEVA", :PIAEVA, "share/nitf/plugins"),
    LibraryProduct("PIAIMB", :PIAIMB, "share/nitf/plugins"),
    LibraryProduct("PIAIMC", :PIAIMC, "share/nitf/plugins"),
    LibraryProduct("PIAPEA", :PIAPEA, "share/nitf/plugins"),
    LibraryProduct("PIAPEB", :PIAPEB, "share/nitf/plugins"),
    LibraryProduct("PIAPRC", :PIAPRC, "share/nitf/plugins"),
    LibraryProduct("PIAPRD", :PIAPRD, "share/nitf/plugins"),
    LibraryProduct("PIATGA", :PIATGA, "share/nitf/plugins"),
    LibraryProduct("PIATGB", :PIATGB, "share/nitf/plugins"),
    LibraryProduct("PIXMTA", :PIXMTA, "share/nitf/plugins"),
    LibraryProduct("PIXQLA", :PIXQLA, "share/nitf/plugins"),
    LibraryProduct("PLTFMA", :PLTFMA, "share/nitf/plugins"),
    LibraryProduct("PRADAA", :PRADAA, "share/nitf/plugins"),
    LibraryProduct("PRJPSB", :PRJPSB, "share/nitf/plugins"),
    LibraryProduct("PTPRAA", :PTPRAA, "share/nitf/plugins"),
    LibraryProduct("REGPTB", :REGPTB, "share/nitf/plugins"),
    LibraryProduct("RPC00B", :RPC00B, "share/nitf/plugins"),
    LibraryProduct("RPFDES", :RPFDES, "share/nitf/plugins"),
    LibraryProduct("RPFHDR", :RPFHDR, "share/nitf/plugins"),
    LibraryProduct("RPFIMG", :RPFIMG, "share/nitf/plugins"),
    LibraryProduct("RSMAPA", :RSMAPA, "share/nitf/plugins"),
    LibraryProduct("RSMDCA", :RSMDCA, "share/nitf/plugins"),
    LibraryProduct("RSMECA", :RSMECA, "share/nitf/plugins"),
    LibraryProduct("RSMGGA", :RSMGGA, "share/nitf/plugins"),
    LibraryProduct("RSMGIA", :RSMGIA, "share/nitf/plugins"),
    LibraryProduct("RSMIDA", :RSMIDA, "share/nitf/plugins"),
    LibraryProduct("RSMPCA", :RSMPCA, "share/nitf/plugins"),
    LibraryProduct("RSMPIA", :RSMPIA, "share/nitf/plugins"),
    LibraryProduct("SECTGA", :SECTGA, "share/nitf/plugins"),
    LibraryProduct("SENSRA", :SENSRA, "share/nitf/plugins"),
    LibraryProduct("SENSRB", :SENSRB, "share/nitf/plugins"),
    LibraryProduct("SNSPSB", :SNSPSB, "share/nitf/plugins"),
    LibraryProduct("SNSRA", :SNSRA, "share/nitf/plugins"),
    LibraryProduct("SOURCB", :SOURCB, "share/nitf/plugins"),
    LibraryProduct("STDIDC", :STDIDC, "share/nitf/plugins"),
    LibraryProduct("STEROB", :STEROB, "share/nitf/plugins"),
    LibraryProduct("STREOB", :STREOB, "share/nitf/plugins"),
    LibraryProduct("TEST_DES", :TEST_DES, "share/nitf/plugins"),
    LibraryProduct("TRGTA", :TRGTA, "share/nitf/plugins"),
    LibraryProduct("USE00A", :USE00A, "share/nitf/plugins"),
    LibraryProduct("XML_DATA_CONTENT", :XML_DATA_CONTENT, "share/nitf/plugins")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
