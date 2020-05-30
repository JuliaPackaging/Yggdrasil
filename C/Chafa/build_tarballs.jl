using BinaryBuilder

name = "Chafa"
version = v"1.4.1"

sources = [
    ArchiveSource("https://hpjansson.org/chafa/releases/chafa-$(version).tar.xz",
                  "46d34034f4c96d120e0639f87a26590427cc29e95fe5489e903a48ec96402ba3"),
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
platforms = filter!(p -> !isa(p, Windows), supported_platforms())

products = [
    LibraryProduct("libchafa", :libchafa),
    ExecutableProduct("chafa", :chafa),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("Glib_jll"),
    Dependency("ImageMagick_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
