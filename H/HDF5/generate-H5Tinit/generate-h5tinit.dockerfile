# Run `docker build --file generate-h5tinit.dockerfile --build-arg cpuarch=amd64 --progress plain .`

ARG cpuarch=amd64 # amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, riscv64, s390x
ARG osversion=12.9

FROM ${cpuarch}/debian:${osversion}

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
        ca-certificates \
        cmake \
        g++ \
        gfortran \
        make \
        ninja-build \
        wget

# Download and build HDF5
ADD https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_5/downloads/hdf5-1.14.5.tar.gz hdf5-1.14.5.tar.gz
RUN tar xzf hdf5-1.14.5.tar.gz
WORKDIR hdf5-1.14.5
RUN mkdir build
WORKDIR build
RUN ../configure --enable-cxx --enable-fortran
RUN make -j${nproc} -C fortran/src H5fortran_types.F90 H5f90i_gen.h H5_gen.F90
RUN make -j${nproc} -C hl/fortran/src H5LTff_gen.F90 H5TBff_gen.F90
# RUN cmake -Bbuilddir -GNinja \
#     -DCMAKE_INSTALL_PREFIX=/hdf5 \
#     -DHDF5_BUILD_CPP_LIB=ON \
#     -DHDF5_BUILD_DOC=OFF \
#     -DHDF5_BUILD_EXAMPLES=OFF \
#     -DHDF5_BUILD_FORTRAN=ON \
#     -DHDF5_BUILD_HL_LIB=ON \
#     -DHDF5_BUILD_TOOLS=OFF \
#     -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
#     -DHDF5_ENABLE_Z_LIB_SUPPORT=OFF \
#     -DONLY_SHARED_LIBS=ON
# RUN cmake --build builddir
# RUN cmake --install builddir
