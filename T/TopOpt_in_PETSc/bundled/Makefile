PETSC_DIR=$(prefix)/lib/petsc/double_real_Int32
PETSC_ARCH=x86_64-linux-gnu_double_real_Int32
CXXFLAGS = -fPIC
CPPFLAGS=-I. -I$(includedir) -I$(PETSC_DIR)/include -I$(PETSC_DIR)/
LDFLAGS= -Wl,-rpath,/workspace/destdir/lib/petsc/double_real_Int32/lib -L/workspace/destdir/lib/petsc/double_real_Int32/lib
LDLIBS= -lpetsc_double_real_Int32 -lopenblas -lpthread -lm -lmpifort -lmpi -lstdc++ -ldl -lgfortran -lm -lgfortran -lm -lgcc_s -lstdc++ -ldl
topopt: main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -o topopt main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o $(LDFLAGS) $(LDLIBS)

libtopopt: TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -shared -o libtopopt.$(dlext) TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o $(LDFLAGS) $(LDLIBS)

myclean:
	rm -rf topopt *.o output* binary* log* makevtu.pyc Restart* 