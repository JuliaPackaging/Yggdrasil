using BinaryBuilder, Pkg

version = v"6.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.gz",
                  "f593745fa47ebfb9ddc467aaafdc2fa1275f0d7250c692ce9761389a90dd8eaf"),
]
