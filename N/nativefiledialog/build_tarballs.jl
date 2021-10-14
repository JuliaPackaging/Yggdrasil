# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nativefiledialog"
version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mlabbe/nativefiledialog.git", "67345b80ebb429ecc2aeda94c478b3bcc5f7888e")
]

# Bash recipes for building across all platforms
script_gtk = raw"""
cd $WORKSPACE/srcdir
cd nativefiledialog/src/
gcc nfd_common.c nfd_gtk.c -Iinclude `pkg-config --cflags --libs gtk+-3.0` -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o libnfd.so
mv libnfd.so ${prefix}/lib/
"""

script_win = raw"""
cd $WORKSPACE/srcdir
cd nativefiledialog/src/
g++ nfd_common.c nfd_win.cpp -lole32 -luuid -Iinclude -O2 -Wall -Wextra -fno-exceptions -shared -o libnfd.dll
mv libnfd.so ${prefix}/lib/
"""
script_mac = raw"""
cd $WORKSPACE/srcdir
cd nativefiledialog/src/
clang nfd_cocoa.m nfd_common.c -framework Foundation -framework AppKit -Iinclude -O2 -Wall -Wextra -fno-exceptions -fPIC -shared -o libnfd.dylib
mv libnfd.so ${prefix}/lib/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libnfd", :libnfd)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"))
    Dependency(PackageSpec(name="Xorg_xproto_jll", uuid="46797783-dccc-5433-be59-056c4bde8513"))
    Dependency(PackageSpec(name="Xorg_kbproto_jll", uuid="060dd47b-79ec-5ba1-a7b2-f4f2f7dcdd0f"))
    Dependency(PackageSpec(name="Xorg_xextproto_jll", uuid="d13bc2ba-d276-5c6f-8a1c-29ed04aab5d0"))
    Dependency(PackageSpec(name="Xorg_inputproto_jll", uuid="84d6cd60-beca-5f49-93c5-789031781a2d"))
    Dependency(PackageSpec(name="Xorg_fixesproto_jll", uuid="cf2f014d-5496-555f-b295-889ac9dfddaa"))
    Dependency(PackageSpec(name="Xorg_randrproto_jll", uuid="0e394dc1-71ae-5c65-abe5-8749687e42d3"))
    Dependency(PackageSpec(name="Xorg_renderproto_jll", uuid="21e99dc2-7dba-5609-a726-b181bd3bbb6c"))
    Dependency(PackageSpec(name="Xorg_damageproto_jll", uuid="17eb5352-d50b-5fdc-b767-c749cd790e65"))
    Dependency(PackageSpec(name="Xorg_xineramaproto_jll", uuid="6a3da44c-33b1-5374-838f-bf0fbf92c29b"))
    Dependency(PackageSpec(name="Xorg_compositeproto_jll", uuid="0af4abc2-9bda-511f-85a5-daebf69421ba"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
