using BinaryBuilder, Pkg

name = "VARNA"
version = v"3.93.0"

# url = "https://varna.lisn.upsaclay.fr/"
# description = "Java component and applet for drawing RNA secondary structure"

sources = [
    FileSource("https://varna.lisn.upsaclay.fr/bin/VARNAv$(version.major)-$(version.minor).jar",
               "276996b0eb54ab7bdbf92a113f0c23d8d3ed8e497d85b6577b3f2065a0dbcf87"),
]

script = raw"""
cd $WORKSPACE/srcdir/

install -Dvm 644 VARNA*.jar ${prefix}/share/VARNA.jar

# VARNA uses GPL as stated here: https://varna.lisn.upsaclay.fr/
install_license /usr/share/licenses/GPL-3.0+
"""

platforms = supported_platforms()

products = [
    FileProduct("share/VARNA.jar", :VARNA_jar)
]

dependencies = Dependency[
    # TODO: depends on java
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
