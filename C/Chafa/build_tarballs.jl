using BinaryBuilder

name = "Chafa"
version = v"1.8.0"

sources = [
    ArchiveSource("https://hpjansson.org/chafa/releases/chafa-$(version).tar.xz",
                  "21ff652d836ba207098c40c459652b2f1de6c8a64fbffc62e7c6319ced32286b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/chafa-*/

if [[ "${target}" == *darwin* ]]; then
    # For some reason building with Clang for macOS doesn't work
    export CC=gcc
fi
if [[ "${proc_family}" == intel ]]; then
    BUILTIN_FUNCS=yes
else
    BUILTIN_FUNCS=no
fi
./autogen.sh \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    ax_cv_gcc_check_x86_cpu_init="${BUILTIN_FUNCS}" \
    ax_cv_gcc_check_x86_cpu_supports="${BUILTIN_FUNCS}"
make -j${nproc}
make install
"""

# Chafa itself does not support Windows
platforms = filter!(!Sys.iswindows, supported_platforms())
# Remove this when we build a newer version for which we can target the former
# experimental platforms
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64") && arch(p) != "armv6l", platforms)

products = [
    LibraryProduct("libchafa", :libchafa),
    ExecutableProduct("chafa", :chafa),
]

dependencies = [
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Glib_jll"; compat="2.59.0"),
    Dependency("ImageMagick_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
