CXXFLAGS = -fPIC
CPPFLAGS =-I. -I$(includedir) -I$(libdir)/petsc/double_real_Int32/include -I$(libdir)/petsc/double_real_Int32/
LDFLAGS = -L${libdir} -Wl,-rpath,${libdir}/petsc/double_real_Int32/lib -L${libdir}/petsc/double_real_Int32/lib
LDLIBS = -lpetsc_double_real_Int32
ifneq (,$(findstring mingw,$(target)))
	LDLIBS += -lmsmpi
else
	LDLIBS += -lmpi
endif

topopt$(exeext): main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CXX) $(CPPFLAGS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

libtopopt.$(dlext): TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	$(CXX) $(CPPFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

clean:
	rm -rf topopt$(exeext) libtopopt.$(dlext) *.o output* binary* log* makevtu.pyc Restart*
