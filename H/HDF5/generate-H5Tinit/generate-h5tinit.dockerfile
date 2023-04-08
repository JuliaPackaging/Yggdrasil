# Run `docker build --file generate-H5Tinit.dockerfile --build-arg cpuarch=amd64 --progress plain .`

ARG cpuarch=amd64 # amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, riscv64

FROM ${cpuarch}/debian:11.5

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
        build-essential \
        ca-certificates \
        wget

# Download and build HDF5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.0/src/hdf5-1.14.0.tar.gz
RUN tar xzf hdf5-1.14.0.tar.gz
WORKDIR hdf5-1.14.0
RUN mkdir build
WORKDIR build
RUN ../configure
# RUN make -j${nproc}
RUN make -j${nproc} -C src H5Tinit.c

ENTRYPOINT cat src/H5Tinit.c
