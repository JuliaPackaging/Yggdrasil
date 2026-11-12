### Instructions for adding a new version of the OCaml toolchain
#
# * update the `version` variable and `sources`
# * To deploy the shard and automatically update your BinaryBuilderBase's
#   `Artifacts.toml`, use the `--deploy` flag to the `build_tarballs.jl` script.
#   You can build & deploy by running:
#
#      julia build_tarballs.jl --debug --verbose --deploy TARGET
#

using BinaryBuilderBase, BinaryBuilder, Pkg.Artifacts

include("../common.jl")

name = "OCamlBase"
version = v"5.3.0"

sources = [
    GitSource("https://github.com/ocaml/ocaml",
              "1ccb919e35f8378834060c503ae953897fe0fb7f"), # 5.3.0
    GitSource("https://github.com/ocaml/dune",
              "76c0c3941798f81dcc13a305d7abb120c191f5fa"),  # 3.19.1
    GitSource("https://github.com/ocaml/ocamlbuild",
              "131ba63a1b96d00f3986c8187677c8af61d20a08"),  # 0.16.1
    GitSource("https://github.com/ocaml/ocamlfind",
              "bd9aad183f0d1c2caf3ec29e4f52bc69361f266d"),  # 1.9.8
    DirectorySource("./bundled"),
]

include("../ocaml_common.jl")
