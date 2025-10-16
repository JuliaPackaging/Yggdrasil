# Run `docker build --file generate-h5tinit.dockerfile --build-arg cpuarch=amd64 --progress plain .`

ARG cpuarch=amd64 # amd64, arm32v5, arm32v7, arm64v8, i386, mips64le, ppc64le, riscv64, s390x
ARG osversion=13.1

FROM ${cpuarch}/debian:${osversion}-slim

# RUN { \
#         echo 'deb http://archive.debian.org/debian buster main contrib non-free' && \
#         echo 'deb http://archive.debian.org/debian-security buster/updates main contrib non-free'; \
#     } >/etc/apt/sources.list && \
#     echo 'Acquire::Check-Valid-Until "false";' >/etc/apt/apt.conf.d/99no-check-valid-until && \

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
ARG gccversion=14
RUN apt-get update && \
    apt-get --yes --no-install-recommends install \
        ca-certificates \
        cmake \
        g++-${gccversion} \
        gcc-${gccversion} \
        gfortran-${gccversion} \
        make \
        ninja-build \
        wget

# Download and build HDF5
ARG commit
ADD https://github.com/HDFGroup/hdf5/archive/${commit}.tar.gz hdf5-${commit}.tar.gz
RUN tar xzf hdf5-${commit}.tar.gz
WORKDIR hdf5-${commit}
RUN if [ ${cpuarch} = arm64v8 ]; then sed -i -e 's/__float128/__float129/g' config/HDFTests.c; fi
RUN sed -i -e 's/__float128/__float129/g' config/HDFTests.c
# We need to enable testing so that the file `tf_gen.F90` is generated.
RUN cmake -Bbuilddir -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=gcc-${gccversion} \
        -DCMAKE_CXX_COMPILER=g++-${gccversion} \
        -DCMAKE_Fortran_COMPILER=gfortran-${gccversion} \
        -DCMAKE_INSTALL_PREFIX=/hdf5 \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DBUILD_TESTING=ON \
        -DHDF5_BUILD_CPP_LIB=ON \
        -DHDF5_BUILD_DOC=OFF \
        -DHDF5_BUILD_EXAMPLES=OFF \
        -DHDF5_BUILD_FORTRAN=ON \
        -DHDF5_BUILD_HL_LIB=ON \
        -DHDF5_BUILD_TOOLS=OFF \
        -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
        -DHDF5_ENABLE_ZLIB_SUPPORT=OFF
RUN cmake --build builddir
RUN cmake --install builddir
