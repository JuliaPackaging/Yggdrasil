PETSC_DIR=$(libdir)/petsc/double_real_Int32
PETSC_ARCH=x86_64-linux-gnu_double_real_Int32
CXXFLAGS = -fPIC
CPPFLAGS=-I. -I$(includedir) -I$(PETSC_DIR)/include -I$(PETSC_DIR)/
LDFLAGS= -Wl,-rpath,${libdir}/petsc/double_real_Int32/lib -L${libdir}/petsc/double_real_Int32/lib
LDLIBS= -lpetsc_double_real_Int32 -lopenblas -lpthread -lm -lmpifort -lmpi -lstdc++ -ldl -lgfortran -lm -lgfortran -lm -lgcc_s -lstdc++ -ldl
topopt$(exeext): main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -o $@ $^ $(LDFLAGS) $(LDLIBS)

libtopopt.$(dlext): TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CC) $(CPPFLAGS) -v -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

myclean:
	rm -rf topopt *.o output* binary* log* makevtu.pyc Restart*
