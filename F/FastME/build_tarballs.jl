using BinaryBuilder, Pkg

name = "FastME"
version = v"2.1.6"
sources = [
    GitSource("https://gite.lirmm.fr/atgc/FastME.git", "4d0ecf8e1f06bd22e25e57dc362594548c3e10d4"),
]


script = raw"""
cd ${WORKSPACE}/srcdir/FastME

install_license /usr/share/licenses/GPL-3.0+

update_configure_scripts --reconf
autoupdate

# Checks from macros `AC_FUNC_MALLOC` and `AC_FUNC_REALLOC` may fail when cross-compiling,
# which can cause configure to remap `malloc` and `realloc` to replacement functions
# `rpl_malloc` and `rpl_realloc`, which will cause a linking error.  For more information,
# see https://stackoverflow.com/q/70725646/2442087
FLAGS=(ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes)

# optimized multi-threading
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
install -Dvm 755 $bindir/fastme${exeext} $bindir/fastmeMP${exeext}

# optimized single-threading
./configure --disable-OpenMP --prefix=$prefix --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make clean
make -j${nproc}
make install
"""


platforms = supported_platforms()

products = [
    ExecutableProduct("fastme", :fastme),
    ExecutableProduct("fastmeMP", :fastmeMP),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
