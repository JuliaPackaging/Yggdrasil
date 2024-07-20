using BinaryBuilder

name = "spdlog"
version = v"1.14.1"

sources = [GitSource("https://github.com/gabime/spdlog.git", "27cb4c76708608465c413f6d0e6b8d99a4d84302")]

script = raw"""
cd ${WORKSPACE}/srcdir/spdlog*
mkdir build
cd build
cmake -S .. -B . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DSPDLOG_FMT_EXTERNAL=ON \
    -DSPDLOG_BUILD_SHARED=ON \
    -DSPDLOG_BUILD_PIC=ON \
    -DSPDLOG_BUILD_EXAMPLE=OFF
make -j${nproc} install
"""

platforms = map(supported_platforms()) do p
    if !Sys.isbsd(p)
        p["cxxstring_abi"] = "cxx11"
    end
    return p
end

products = [LibraryProduct("libspdlog", :libspdlog)]

dependencies = [Dependency("Fmt_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
