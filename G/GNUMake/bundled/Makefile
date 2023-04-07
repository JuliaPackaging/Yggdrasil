CPPFLAGS = -DWINDOWS32 -DHAVE_CONFIG_H -I./src -I./lib -I./src/w32/include -I./src/w32 -I./src/w32/subproc
CFLAGS = -mthreads -Wall -std=gnu99 -gdwarf-2 -g3 -O2

$(bindir)/make$(exeext): src/ar.o src/arscan.o src/commands.o src/default.o src/dir.o src/expand.o src/file.o src/function.o src/getopt.o src/getopt1.o src/guile.o src/hash.o src/implicit.o src/job.o src/load.o src/loadapi.o src/main.o src/misc.o src/output.o src/read.o src/remake.o src/remote-stub.o src/rule.o src/shuffle.o src/signame.o src/strcache.o src/variable.o src/version.o src/vpath.o src/w32/pathstuff.o src/w32/w32os.o src/w32/compat/posixfcn.o src/w32/subproc/sub_proc.o src/w32/subproc/misc.o src/w32/subproc/w32err.o lib/fnmatch.o lib/glob.o lib/getloadavg.o
	cc $(CFLAGS) -o $(bindir)/make$(exeext) -lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid -lodbc32 -lodbccp32 $^ -Wl,--out-implib=$(prefix)/lib/libgnumake-1.dll.a
