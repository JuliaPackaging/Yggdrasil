using BinaryBuilder

name = "patch"
version_string = "2.8.1"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/patch/patch-$(version_string).tar.xz",
                  "3240c7959c5347c8ed347e3c4201c0337bf4240d5cf09d68889e58eeaba30e17"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/patch*
configure_flags=()
if [[ ${nbits} == 32 ]]; then
   # We disable the year 2038 check because we don't have an alternative on the affected systems
   configure_flags+=(--disable-year2038)
fi
./configure --prefix=${prefix} --host=${target} ${configure_flags[@]}
make -j${nproc}
make install
"""

# Windows build fails spectacularly; some patching required
platforms = filter(!Sys.iswindows, supported_platforms())
products = [
    ExecutableProduct("patch", :patch),
]
dependencies = Dependency[]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
