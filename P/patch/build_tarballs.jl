using BinaryBuilder

name = "patch"
version_string = "2.8"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/patch/patch-$(version_string).tar.xz",
                  "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3"),
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
