# Run `docker build --file generate-h5tinit.dockerfile --build-arg cpuarch=amd64 --progress plain .`

ARG cpuarch=amd64 # amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, riscv64

FROM ${cpuarch}/debian:12.5
# FROM ${cpuarch}/debian:unstable

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
        ca-certificates \
        g++ \
        gfortran \
        make \
        wget

# Download and build HDF5
RUN wget https://github.com/HDFGroup/hdf5/releases/download/hdf5_1.14.4.2/hdf5-1.14.4-2.tar.gz
RUN tar xzf hdf5-1.14.4-2.tar.gz
WORKDIR hdf5-1.14.4-2
RUN mkdir build
WORKDIR build
RUN ../configure --enable-cxx --enable-fortran
RUN make -j${nproc} -C fortran/src H5fortran_types.F90 H5f90i_gen.h H5_gen.F90
RUN make -j${nproc} -C hl/fortran/src H5LTff_gen.F90 H5TBff_gen.F90
