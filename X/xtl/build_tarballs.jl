# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "xtl"
version = v"0.7.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/xtl", "a7c1c5444dfc57f76620391af4c94785ff82c8d6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xtl
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    # This is a header-only library without any binary products
    FileProduct("include/xtl/xany.hpp", :xany),
    FileProduct("include/xtl/xbase64.hpp", :xbase64),
    FileProduct("include/xtl/xbasic_fixed_string.hpp", :xbasic_fixed_string),
    FileProduct("include/xtl/xclosure.hpp", :xclosure),
    FileProduct("include/xtl/xcompare.hpp", :xcompare),
    FileProduct("include/xtl/xcomplex.hpp", :xcomplex),
    FileProduct("include/xtl/xcomplex_sequence.hpp", :xcomplex_sequence),
    FileProduct("include/xtl/xdynamic_bitset.hpp", :xdynamic_bitset),
    FileProduct("include/xtl/xfunctional.hpp", :xfunctional),
    FileProduct("include/xtl/xhalf_float.hpp", :xhalf_float),
    FileProduct("include/xtl/xhalf_float_impl.hpp", :xhalf_float_impl),
    FileProduct("include/xtl/xhash.hpp", :xhash),
    FileProduct("include/xtl/xhierarchy_generator.hpp", :xhierarchy_generator),
    FileProduct("include/xtl/xiterator_base.hpp", :xiterator_base),
    FileProduct("include/xtl/xjson.hpp", :xjson),
    FileProduct("include/xtl/xmasked_value.hpp", :xmasked_value),
    FileProduct("include/xtl/xmasked_value_meta.hpp", :xmasked_value_meta),
    FileProduct("include/xtl/xmeta_utils.hpp", :xmeta_utils),
    FileProduct("include/xtl/xmultimethods.hpp", :xmultimethods),
    FileProduct("include/xtl/xoptional.hpp", :xoptional),
    FileProduct("include/xtl/xoptional_meta.hpp", :xoptional_meta),
    FileProduct("include/xtl/xoptional_sequence.hpp", :xoptional_sequence),
    FileProduct("include/xtl/xplatform.hpp", :xplatform),
    FileProduct("include/xtl/xproxy_wrapper.hpp", :xproxy_wrapper),
    FileProduct("include/xtl/xsequence.hpp", :xsequence),
    FileProduct("include/xtl/xspan.hpp", :xspan),
    FileProduct("include/xtl/xspan_impl.hpp", :xspan_impl),
    FileProduct("include/xtl/xsystem.hpp", :xsystem),
    FileProduct("include/xtl/xtl_config.hpp", :xtl_config),
    FileProduct("include/xtl/xtype_traits.hpp", :xtype_traits),
    FileProduct("include/xtl/xvariant.hpp", :xvariant),
    FileProduct("include/xtl/xvariant_impl.hpp", :xvariant_impl),
    FileProduct("include/xtl/xvisitor.hpp", :xvisitor),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
