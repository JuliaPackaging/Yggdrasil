using BinaryBuilder, Pkg

name = "PhyML"
version = v"3.3.20210609" # latest passing build
hash = "eb1009ebef100d34696db95301ba7cb55dceeb40"
sources = [
    GitSource("https://github.com/stephaneguindon/phyml.git", hash),
    DirectorySource("./bundled")
]

script = raw"""
cd ${WORKSPACE}/srcdir/phyml
install_license ${WORKSPACE}/srcdir/phyml/COPYING

# disable -march=native flag
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done    

# generate config scripts
./autogen.sh

# make single-process version 
./configure ${extraflags} --enable-phyml --prefix=$prefix --build=${MACHTYPE} --host=${target}
make clean & make -j${nproc}
install -Dvm 755 ./src/phyml${exeext} ${bindir}/phyml${exeext}

# Make MPI version
./configure ${extraflags} --enable-phyml-mpi --prefix=$prefix --build=${MACHTYPE} --host=${target}
make clean & make -j${nproc}
install -Dvm 755 ./src/phyml-mpi${exeext} ${bindir}/phymlMPI${exeext}
"""

platforms = supported_platforms()

# similar error for below platforms
# [16:29:05] Undefined symbols for architecture arm64:
# [16:29:05]   "_rpl_malloc", referenced from:
# [16:29:05]       _Alloc_TBE_Matrices in make.o
# [16:29:05]   "_rpl_realloc", referenced from:
# [16:29:05]       _mRealloc in utilities.o
# [16:29:05]       _Remove_Duplicates in utilities.o
# [16:29:05]       _Get_Bip in utilities.o
# [16:29:05]       _TIPO_Untangle_Node in tiporder.o
# [16:29:05]       _Read_Nexus_Translate in nexus.o
# [16:29:05]       _Read_Nexus_Tree in nexus.o
# [16:29:05]       _XML_Load_File in xml.o
# [16:29:05]       ...
# [16:29:05] ld: symbol(s) not found for architecture arm64
# [16:29:05] clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
_rpl_malloc_error_triplets = [
    "aarch64-linux-musl", 
    "armv6l-linux-musleabihf", 
    "armv7l-linux-musleabihf",
    "i686-linux-musl",
    "aarch64-apple-darwin",
    "x86_64-apple-darwin",
    ]
filter!(p->triplet(p) ∉ _rpl_malloc_error_triplets, platforms)

# [16:08:21] /opt/i686-w64-mingw32/bin/../i686-w64-mingw32/sys-root/lib/../lib/libmingw32.a(lib32_libmingw32_a-crt0_c.o): In function `main':
# [16:08:21] /workspace/srcdir/mingw-w64-v7.0.0/mingw-w64-crt/crt/crt0_c.c:18: undefined reference to `WinMain@16'
# [16:08:21] collect2: error: ld returned 1 exit status
# [16:08:21] make[2]: Leaving directory '/workspace/srcdir/phyml/src'
# [16:08:21] make[1]: Leaving directory '/workspace/srcdir/phyml'
# [16:08:21] make[2]: *** [Makefile:1695: phyml.exe] Error 1
# [16:08:21] make[1]: *** [Makefile:365: all-recursive] Error 1
# [16:08:21] make: *** [Makefile:306: all] Error 2
# [16:08:21]  ---> make -j${nproc}
# [16:08:21]  ---> make -j${nproc}
# [16:08:21] Previous command 1382 exited with 2
filter!(p-> triplet(p) != "i686-w64-mingw32", platforms)

# [15:56:47] i686-w64-mingw32-gcc  -std=c99 -O3 -fomit-frame-pointer -funroll-loops -Wall -Winline -finline    -o phyml.exe   -lm 
# [15:56:47] rm -f *.o
# [15:56:47] make[1]: Leaving directory '/workspace/srcdir/phyml/src'
# [15:56:47] make[2]: Leaving directory '/workspace/srcdir/phyml/src'
# [15:56:47] make[1]: Leaving directory '/workspace/srcdir/phyml'
# [15:56:47] make[2]: i686-w64-mingw32-gcc: No such file or directory
# [15:56:47] make[2]: *** [Makefile:1695: phyml.exe] Error 127
# [15:56:47] make[2]: *** Waiting for unfinished jobs....
# [15:56:47] make[1]: *** [Makefile:365: all-recursive] Error 1
# [15:56:47] make: *** [Makefile:306: all] Error 2
filter!(p-> triplet(p) != "x86_64-w64-mingw32", platforms)

products = [
    ExecutableProduct("phyml", :phyml),
    ExecutableProduct("phymlMPI", :phymlMPI),
]

dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"); platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")