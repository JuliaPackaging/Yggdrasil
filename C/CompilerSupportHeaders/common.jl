using BinaryBuilder

function build_csh(ARGS, version::VersionNumber;
                   # Note: use preferred_gcc_version=v"100" to always force
                   # latest compatible version.
                   preferred_gcc_version::VersionNumber,
                   julia_compat::String,
                   )
    name = "CompilerSupportHeaders"

    script = raw"""
mkdir -p ${includedir}
# Copy all the libstdc++ and libgomp headers:
cp -Rv /opt/${target}/${target}/include/c++/ ${includedir} || true
# This doesn't grab any of the std C headers, but they are in Clang_jll already
cp -Rv /opt/${target}/lib/gcc/${target}/*/include/{omp.h,openacc.h} ${includedir} || true

# Install license (we license these all as GPL3, since they're from GCC)
install_license /usr/share/licenses/GPL-3.0+
"""

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = expand_gfortran_versions(supported_platforms())

    # All products are headers
    products = Product[
        FileProduct("include/omp.h", :omp),
        FileProduct("include/openacc.h", :openacc),
        # C++ headers we'll leave alone.
    ]

    build_tarballs(ARGS, name, version, [], script, platforms, products, []; preferred_gcc_version, julia_compat)
end

