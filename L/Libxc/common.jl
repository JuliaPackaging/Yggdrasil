using BinaryBuilder, Pkg

version = v"6.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.com/libxc/libxc/-/archive/$(version)/libxc-$(version).tar.gz",
                  "0c774e8e195dd92800b9adf3df5f5721e29acfe9af4b191a9937c7de4f9aa9f6"),
]
