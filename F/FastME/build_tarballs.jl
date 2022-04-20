using BinaryBuilder, Pkg

name = "FastME"
version = v"2.1.6"
sources = [
    GitSource("https://gite.lirmm.fr/atgc/FastME.git", "4d0ecf8e1f06bd22e25e57dc362594548c3e10d4"),
]


script = raw"""
cd ${WORKSPACE}/srcdir/FastME

# using license as specified here: http://www.atgc-montpellier.fr/fastme/binaries.php
wget https://www.gnu.org/licenses/gpl-3.0.txt > LICENSE

update_configure_scripts --reconf
autoupdate

# optimized multi-threading
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install -Dvm 755 $bindir/fastme${exeext} $bindir/fastmeMP${exeext}

# optimized single-threading
./configure --disable-OpenMP --prefix=$prefix --build=${MACHTYPE} --host=${target}
make clean
make -j${nproc}
make install
"""


platforms = supported_platforms()
# errors when glibc is not available on linux-musl and apple platforms
# [13:38:50] Undefined symbols for architecture arm64:
# [13:38:50]   "_rpl_realloc", referenced from:
# [13:38:50]       _Read_Branch_Label in p_bootstrap.o
# [13:38:50]       _Make_New_Edge_Label in p_bootstrap.o
# [13:38:50] ld: symbol(s) not found for architecture arm64
filter!(p-> libc(p) != "musl", platforms)
filter!(p-> !(Sys.isapple(p)), platforms)

products = [
    ExecutableProduct("fastme", :fastme),
    ExecutableProduct("fastmeMP", :fastmeMP),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
