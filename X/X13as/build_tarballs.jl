# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "X13as"
version = v"1.1.60"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_asciisrc-v1-1-b60.tar.gz", "2bd53953a1bdd238a128b89e95e8e5fc14f33aa4a9e4c7f0fc3fe7323b73131c", unpack_target="./x13as_asciisrc"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_htmlsrc-v1-1-b60.tar.gz", "642f6b6a969c5c311252ca83845ea391ab8c3d59840c4dc2508f9c86095c7757", unpack_target="./x13as_htmlsrc"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_ascii-v1-1-b60.tar.gz", "593e6b63024181c9550c281587bfeb28b2dcf1658f4495d42eb8933c6868ee36"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_html-v1-1-b60.tar.gz", "a9f55329373092c33ed5b1908094c0dc037cc05bf8789bd4f7156abcaa2200ed"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
########## First, build and install the ascii version
pushd x13as_asciisrc
###  Fix a bug in adpdrg.f in x13as_asciisrc v1.1.b60
sed -i -e "s|'\,T|'|" adpdrg.f
if [[ "${target}" == *-apple-* ]]
then
    # the -static flag doesn't work in macos; also disable -s linker flag
    sed -e "s/\-static//" -i makefile.gf
    make -j${nproc} -f makefile.gf PROGRAM="x13as_ascii${exeext}" LDFLAGS=
else
    make -j${nproc} -f makefile.gf PROGRAM="x13as_ascii${exeext}"
fi
mkdir -p ${bindir}
install -Dvm 755 "x13as_ascii${exeext}" "${bindir}/x13as_ascii${exeext}"
popd
########## Second, build and install the html version
pushd x13as_htmlsrc
###  They left the debug flags here for some reason
sed -e "s/FFLAGS.*/FFLAGS=-O2/" -i makefile.gf
if [[ "${target}" == *-apple-* ]]
then
    # the -static flag doesn't work in macos; also disable -s linker flag
    sed -e "s/\-static//" -i makefile.gf
    make -j${nproc} -f makefile.gf PROGRAM="x13as_html${exeext}" LDFLAGS=
else
    make -j${nproc} -f makefile.gf PROGRAM="x13as_html${exeext}"
fi
install -Dvm 755 "x13as_html${exeext}" "${bindir}/x13as_html${exeext}"
popd
########## Third, install the docs and the test examples
docsdir="${prefix}/docs"
mkdir -p "${docsdir}"
install -Dvm 644 "x13as/testairline.spc" "${docsdir}/testairline.spc"
install -Dvm 644 "x13as/docs/docx13as.pdf" "${docsdir}/docx13as.pdf"
install -Dvm 644 "x13as/docs/qrefX13ASunix.pdf" "${docsdir}/qrefX13ASunix.pdf"
install -Dvm 644 "x13as/docs/docX13ASHTML.pdf" "${docsdir}/docX13ASHTML.pdf"
install -Dvm 644 "x13as/docs/qrefX13ASHTMLunix.pdf" "${docsdir}/qrefX13ASHTMLunix.pdf"
########## Fourth, install license files
install_license x13as_license.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("x13as_ascii", :x13as_ascii),
    ExecutableProduct("x13as_html", :x13as_html),
    FileProduct("docs/testairline.spc", :testairline_spc),
    FileProduct("docs/docx13as.pdf", :docx13as_pdf),
    FileProduct("docs/qrefX13ASunix.pdf", :qrefX13ASunix_pdf),
    FileProduct("docs/docX13ASHTML.pdf", :docX13ASHTML_pdf),
    FileProduct("docs/qrefX13ASHTMLunix.pdf", :qrefX13ASHTMLunix_pdf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
