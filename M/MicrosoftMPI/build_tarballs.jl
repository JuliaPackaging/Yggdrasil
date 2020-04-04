using BinaryBuilder, Pkg

name = "MicrosoftMPI"
version = v"10.1.2"
sources = [
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisetup.exe",
                  "c305ce3f05d142d519f8dd800d83a4b894fc31bcad30512cefb557feaccbe8b4"),
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisdk.msi",
                  "d8c07fc079d35d373e14a6894288366b74147539096d43852cb0bbae32b33e44"),
]

script = raw"""
apk add p7zip

cd ${WORKSPACE}/srcdir/
7z x msmpisetup.exe -o$prefix
7z x msmpisdk.msi -o$prefix

cd ${WORKSPACE}/destdir/

chmod +x *.exe

mkdir -p bin
mv *.exe *.dll bin
mkdir -p lib
mv *.lib lib
mkdir -p include
mv *.h *.man include
mkdir -p src
mv *.f90 src
mkdir -p share/licenses/MicrosoftMPI
mv *.txt *.rtf share/licenses/MicrosoftMPI
"""

platforms = filter!(p -> isa(p, Windows), supported_platforms())

products = [
    LibraryProduct("msmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
]

dependencies = [
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
