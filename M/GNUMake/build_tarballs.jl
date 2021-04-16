# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GNUMake"
version = v"4.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/make/make-4.3.tar.gz", "e05fdde47c5f7ca45cb697e973894ff4f5d79e13b750ed57d7b66d8defc78e19"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
# Really ugly straight translation of the build_w32.bat file here. Could probably still use make file
# but this is more or less a translation of the "official" install method.
script = raw"""
cd $WORKSPACE/srcdir/make-4.3
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/make-4.3_undef-HAVE_STRUCT_DIRENT_D_TYPE.patch
if [[ "${target}" == *-mingw* ]]; then
    
    mkdir ${prefix}/src
    mkdir ${prefix}/src/w32
    mkdir ${prefix}/src/w32/compat
    mkdir ${prefix}/src/w32/subproc
    mkdir ${prefix}/lib
    mkdir ${prefix}/bin
    cp src/config.h.W32 ${prefix}/src/config.h
    cp lib/glob.in.h ${prefix}/lib/glob.h
    cp lib/fnmatch.in.h ${prefix}/lib/fnmatch.h
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/ar.obj -c src/ar.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/arscan.obj -c src/arscan.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/commands.obj -c src/commands.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/default.obj -c src/default.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/dir.obj -c src/dir.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/expand.obj -c src/expand.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/file.obj -c src/file.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/function.obj -c src/function.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/getopt.obj -c src/getopt.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/getopt1.obj -c src/getopt1.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/guile.obj -c src/guile.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/hash.obj -c src/hash.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/implicit.obj -c src/implicit.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/job.obj -c src/job.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/load.obj -c src/load.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/loadapi.obj -c src/loadapi.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/main.obj -c src/main.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/misc.obj -c src/misc.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/output.obj -c src/output.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/read.obj -c src/read.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/remake.obj -c src/remake.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/remote-stub.obj -c src/remote-stub.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/rule.obj -c src/rule.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/signame.obj -c src/signame.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/strcache.obj -c src/strcache.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/variable.obj -c src/variable.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/version.obj -c src/version.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/vpath.obj -c src/vpath.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/pathstuff.obj -c src/w32/pathstuff.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/w32os.obj -c src/w32/w32os.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/compat/posixfcn.obj -c src/w32/compat/posixfcn.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/subproc/misc.obj -c src/w32/subproc/misc.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/subproc/sub_proc.obj -c src/w32/subproc/sub_proc.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/src/w32/subproc/w32err.obj -c src/w32/subproc/w32err.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/lib/fnmatch.obj -c lib/fnmatch.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/lib/glob.obj -c lib/glob.c
    cc -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2  -I${prefix}/src -I./src -I${prefix}/lib -I./lib -I./src/w32/include -DWINDOWS32 -DHAVE_CONFIG_H -o ${prefix}/lib/getloadavg.obj -c lib/getloadavg.c
    cc -mthreads -gdwarf-2 -g3 -O2 -o ${prefix}/bin/make.exe ${prefix}/src/ar.obj ${prefix}/src/arscan.obj ${prefix}/src/commands.obj ${prefix}/src/default.obj ${prefix}/src/dir.obj ${prefix}/src/expand.obj ${prefix}/src/file.obj ${prefix}/src/function.obj ${prefix}/src/getopt.obj ${prefix}/src/getopt1.obj ${prefix}/src/guile.obj ${prefix}/src/hash.obj ${prefix}/src/implicit.obj ${prefix}/src/job.obj ${prefix}/src/load.obj ${prefix}/src/loadapi.obj ${prefix}/src/main.obj ${prefix}/src/misc.obj ${prefix}/src/output.obj ${prefix}/src/read.obj ${prefix}/src/remake.obj ${prefix}/src/remote-stub.obj ${prefix}/src/rule.obj ${prefix}/src/signame.obj ${prefix}/src/strcache.obj ${prefix}/src/variable.obj ${prefix}/src/version.obj ${prefix}/src/vpath.obj ${prefix}/src/w32/pathstuff.obj ${prefix}/src/w32/w32os.obj ${prefix}/src/w32/compat/posixfcn.obj ${prefix}/src/w32/subproc/misc.obj ${prefix}/src/w32/subproc/sub_proc.obj ${prefix}/src/w32/subproc/w32err.obj ${prefix}/lib/fnmatch.obj ${prefix}/lib/glob.obj ${prefix}/lib/getloadavg.obj -lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid -lodbc32 -lodbccp32 -Wl,--out-implib=${prefix}/lib/libgnumake-1.dll.a
    rm -rf ${prefix}/src
    find ${prefix}/ -type f -name '*.obj' -delete
else
    ./configure --build=${MACHTYPE} --prefix=$prefix --host=${target} --disable-nls
    make -j${nproc}
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("make",:make)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
