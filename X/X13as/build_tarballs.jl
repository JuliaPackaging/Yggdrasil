# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "X13as"
version = v"1.1.62"
version_string = "v$(version.major)-$(version.minor)-b$(version.patch)"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_asciisrc-$(version_string).tar.gz", "82796c84b54891474df1a6ffb16be7bf7bd4a992e3679158645c888e6cddda12"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_htmlsrc-$(version_string).tar.gz", "b033b05a00f3b0af9e866ce261f437f348967ccea34bc3003fd59c477f663859"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_ascii-$(version_string).tar.gz", "a91d37bb2fef46237e1eadd7d9b4f1c00a422d58f6b286c9bfe485289e8ac6f5"),
    ArchiveSource("https://www2.census.gov/software/x-13arima-seats/x13as/unix-linux/program-archives/x13as_html-$(version_string).tar.gz", "96a82b100270f5b4645b3d6b5806e4446f79402ae73adc15beb39a93b7ac9170"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
########## First, build and install the ascii version
pushd x13as_asciisrc-*
###  Remove the stray T argument in the CRLF source.
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
pushd x13as_htmlsrc-*
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
install -Dvm 644 "x13as/docs/docX13AS.pdf" "${docsdir}/docx13as.pdf"
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
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="0.5, 1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
