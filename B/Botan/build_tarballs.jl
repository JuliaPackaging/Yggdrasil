# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Botan"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://botan.randombit.net/releases/Botan-$(version).tar.xz",
        "71843afcc0a2c585f8f33fa304f0b58ae4b9c5d8306f894667b3746044277557",
    ),
    FileSource(
        "https://github.com/joseluisq/macosx-sdks/releases/download/13.3/MacOSX13.3.sdk.tar.xz",
        "518e35eae6039b3f64e8025f4525c1c43786cc5cf39459d609852faf091e34be",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
target_triplet=(${target//-/ })

# The preinstalled MacOSX SDK lacks support for C++20.
# Replace it with a newer version that has full support.
if [[ "${target}" == *"apple-darwin"* ]]; then
    cd ${WORKSPACE}/srcdir
    tar xvf MacOSX*.sdk.tar.xz
    mount --bind MacOSX*.sdk /opt/${target}/${target}/sys-root
    export MACOSX_DEPLOYMENT_TARGET=$(echo MacOSX*.sdk | grep -oP '\d+\.\d')
fi

# BinaryBuilder doesn't allow using "-march" even where it makes sense.
# Remove the code from the ${CXX} wrapper that is responsible for this.
if [[ "${target}" == *"aarch64"* ]]; then
    sed -i '/Cannot force an architecture via -march/,+1 s/^/: #/' $(which ${CXX})
fi

# The configure script will define "_WIN32_WINNT", which should only be set once.
# Remove the additional definition in the ${CXX} wrapper.
if [[ "${target}" == *"mingw32"* ]]; then
    sed -i '/_WIN32_WINNT/d' $(which ${CXX})
fi

cd ${WORKSPACE}/srcdir/Botan-*

# Extract value for "--cpu" option.
cpu=${target_triplet[0]}

# Extract value for "--os" option.
supported_oss=$(./configure.py --list-os-features | \
    cut -f2- -d" " | tr -d ! | tr " " "\n" | sort -u)
if [[ "${supported_oss}" == *"${target_triplet[1]}"* ]]; then
    os=${target_triplet[1]}
else
    os=$(echo ${target_triplet[2]} | sed -r 's/[^a-z]+$//')
fi

# Extract value for "--cc" option.
if [[ "$(cc 2>&1)" == *"clang"* ]]; then
    cc=clang
else
    cc=gcc
fi

# Specify build options.
opts="--build-targets=shared --without-documentation \
    --prefix=${prefix} --cpu=${cpu} --os=${os} --cc=${cc}"

# Disable features that are not supported by all build environments.
opts="${opts} --without-os-feature=explicit_bzero,getentropy,getrandom"

# Fix the error "undefined reference to '__stack_chk_fail_local'".
# Disable stack protection as a (temporary) workaround.
if [[ "${target}" == *"i686-linux-musl"* ]]; then
    opts="${opts} --without-stack-protector"
fi

# To be compatible with Julia 1.6.3, build environments with GCC 12 or higher can't be used.
# Unfortunately, GCC 11 comes shipped as version 11.1.0, while Botan wants at least 11.2.
# Building with 11.1.0 only fails because of its buggy support for using-enum declarations.
# To remedy this, modify Botan's source such that these declarations aren't used anymore.
if [[ "${cc}" == "gcc" ]]; then
    f () { for x in $1; do sed -i -r "s/$x::($2)/$3::\1/g" ${@:4}; done }
    f "Sphincs_Address" '\w*(Compression|Hash|Tree|Generation)' "Sphincs_Address_Type" \
        src/lib/pubkey/sphincsplus/sphincsplus_common/*.{h,cpp}
    f "Alert" '[A-Z]+\w*[A-Z]+\w*|None' "AlertType" \
        src/lib/tls{,/*,/*/*}/*.{h,cpp}
    f "Group_Params Named_Group" 'e?[A-Z0-9_]' "Group_Params_Code" \
        src/lib/tls{,/*}/*.{h,cpp}
    f "Protocol_Version" 'D?TLS\w*' "Version_Code" \
        src/lib/tls{,/*}/*.{h,cpp}
fi

# Finally, let's build.
./configure.py ${opts}
make -j${nproc}
make install
install_license license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct(["libbotan-3", "libbotan"], :libbotan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"11.1.0",
    julia_compat = "1.6.3",
)
