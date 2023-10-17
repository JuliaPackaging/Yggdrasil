# Run `docker build --file generate-h5tinit.dockerfile --build-arg cpuarch=amd64 --progress plain .`

ARG cpuarch=amd64 # amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, riscv64

FROM ${cpuarch}/debian:11.6
# FROM ${cpuarch}/debian:unstable
# FROM ${cpuarch}/ubuntu:18.04

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
        build-essential \
        ca-certificates \
        g++ \
        gfortran \
        wget

# Download and build HDF5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.2/src/hdf5-1.14.2.tar.gz
RUN tar xzf hdf5-1.14.2.tar.gz
WORKDIR hdf5-1.14.2
# RUN wget -O bin/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
# RUN wget -O bin/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
RUN mkdir build
WORKDIR build
RUN ../configure --enable-cxx --enable-fortran
RUN make -j${nproc} -C src H5Tinit.c
RUN make -j${nproc} -C fortran/src H5fortran_types.F90 H5f90i_gen.h H5_gen.F90
RUN make -j${nproc} -C hl/fortran/src H5LTff_gen.F90 H5TBff_gen.F90
