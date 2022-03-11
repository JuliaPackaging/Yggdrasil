PETSC_DIR=$(prefix)/lib/petsc/double_real_Int32
PETSC_ARCH=x86_64-linux-gnu_double_real_Int32
CXXFLAGS = -fPIC
CPPFLAGS=-I. -I$(includedir) -I$(PETSC_DIR)/include -I$(PETSC_DIR)/
LDFLAGS= -Wl,-rpath,/workspace/destdir/lib/petsc/double_real_Int32/lib -L/workspace/destdir/lib/petsc/double_real_Int32/lib -Wl,-rpath,/workspace/destdir/lib -L/workspace/destdir/lib -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64 -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64 -Wl,-rpath,/opt/x86_64-linux-gnu/lib/gcc/x86_64-linux-gnu/9.1.0 -L/opt/x86_64-linux-gnu/lib/gcc/x86_64-linux-gnu/9.1.0 -Wl,-rpath,/opt/x86_64-linux-gnu/lib/gcc -L/opt/x86_64-linux-gnu/lib/gcc -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib64 -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib64 -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/lib64 -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/lib64 -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/lib -Wl,-rpath,/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/lib -L/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root/usr/lib
LDLIBS= -l:libpetsc_double_real_Int32.so -lopenblas -lpthread -lm -lmpifort -lmpi -lstdc++ -ldl -lgfortran -lm -lgfortran -lm -lgcc_s -lstdc++ -ldl
topopt: main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -o topopt main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o $(LDFLAGS) $(LDLIBS)

libtopopt: TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -shared -o libtopopt.$(dlext) TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o $(LDFLAGS) $(LDLIBS)

myclean:
	rm -rf topopt *.o output* binary* log* makevtu.pyc Restart* 