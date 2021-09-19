PETSC_DIR=${prefix}
PETSC_ARCH=x86_64-linux-gnu_double_real_Int32
CFLAGS = -I. -fPIC -g
FFLAGS=
CPPFLAGS=-I.
FPPFLAGS=
LOCDIR=
EXAMPLESC=
EXAMPLESF=
MANSEC=
CLEANFILES=
NP=

include ${PETSC_DIR}/lib/petsc/conf/variables
include ${PETSC_DIR}/lib/petsc/conf/rules
include ${PETSC_DIR}/lib/petsc/conf/test
$(info $$PETSC_SYS_LIB is [${PETSC_SYS_LIB}])
topopt: main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	-${CLINKER} -o topopt main.o TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o ${PETSC_SYS_LIB}
libtopopt: TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o
	-${CLINKER} -o libtopopt.${dlext} TopOpt.o LinearElasticity.o MMA.o Filter.o PDEFilter.o MPIIO.o ${PETSC_SYS_LIB} -shared
myclean:
	rm -rf topopt *.o output* binary* log* makevtu.pyc Restart* 

