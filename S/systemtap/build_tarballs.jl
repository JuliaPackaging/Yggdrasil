using BinaryBuilder

name = "systemtap"
version = v"4.6"
sources = [
    GitSource("https://github.com/cdkey/systemtap.git", "cbb34b7244ba60cb0904d61dc9167290855106aa")
]

script = raw"""
apk add gettext

cd ${WORKSPACE}/srcdir/systemtap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j all
make install

"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(Sys.islinux, platforms)
filter!(p -> libc(p) == "glibc", platforms)


products = [
    ExecutableProduct("stap", :stap),
    ExecutableProduct("stap-merge", :stapmerge),
    ExecutableProduct("stap-report", :stapreport),
    ExecutableProduct("stapbpf", :stapbpf),
    ExecutableProduct("staprun", :staprun),
    ExecutableProduct("stapsh", :stapsh),
    ExecutableProduct("dtrace", :dtrace),
]


dependencies = [
    Dependency("Elfutils_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
