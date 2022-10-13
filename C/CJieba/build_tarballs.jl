using BinaryBuilder, Pkg

name = "CJieba"
version = v"0.3.0"

sources = [
    GitSource("https://github.com/yanyiwu/cjieba.git",
              "1db462d33255aff08802c248b6d6e59202b5619e"),
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir $libdir $prefix/share
cd cjieba
install_license LICENSE 
c++ -o "$libdir/libcjieba.$dlext" lib/jieba.cpp -shared -fPIC -I./deps/ -std=c++11
cp -va dict $prefix/share/
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libcjieba", :libcjieba),
    FileProduct("share/dict/hmm_model.utf8", :hmm_model),
    FileProduct("share/dict/idf.utf8", :idf),
    FileProduct("share/dict/jieba.dict.utf8", :jieba_dict),
    FileProduct("share/dict/stop_words.utf8", :stop_words),
    FileProduct("share/dict/user.dict.utf8", :user_dict)
]

dependencies = Dependency[
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6"
)
