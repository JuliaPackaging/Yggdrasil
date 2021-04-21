cd lib && tar -xvzf blas-3.8.0.tgz \
    && cd BLAS-3.8.0 && make \
    && cd ../.. 

## compile by hand

CCFLAGS="-fPIC -DNDEBUG  -Iinclude -O2 -Wall  -std=gnu99 -mfpmath=sse -msse2 -mstackrealign"
FCFLAGS="-fPIC -fno-optimize-sibling-calls -O2  -mfpmath=sse -msse2 -mstackrealign"

gfortran ${FCFLAGS} -c src/portsrc.f -o src/portsrc.o 
gfortran ${FCFLAGS} -c src/d1mach.f -o src/d1mach.o 
gcc ${CCFLAGS} -c src/port2.c -o src/port.o
gfortran -shared -static-libgcc -o libnlminb.${dlext} src/portsrc.o src/d1mach.o src/port.o lib/BLAS-3.8.0/blas_LINUX.a
