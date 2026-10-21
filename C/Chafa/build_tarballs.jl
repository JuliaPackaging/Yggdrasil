using BinaryBuilder

name = "Chafa"
version = v"1.18.3"

sources = [
    ArchiveSource("https://hpjansson.org/chafa/releases/chafa-$(version).tar.xz",
                  "fb995ef21dce6c73dd0dd454ba3e0f7fac08e053ea16060a2e5ce69a3746ee27"),
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

products = [
    LibraryProduct("libchafa", :libchafa),
    ExecutableProduct("chafa", :chafa),
]

dependencies = [
    Dependency("FreeType2_jll"; compat="2.14.3"),
    Dependency("Glib_jll"; compat="2.88.3"),
    Dependency("ImageMagick_jll"; compat="7.1.2029"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"5")
