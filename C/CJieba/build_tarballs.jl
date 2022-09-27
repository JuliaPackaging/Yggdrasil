using BinaryBuilder, Pkg

name = "CJieba"
version = v"0.3.0"

sources = [
    ArchiveSource(
        "https://github.com/yanyiwu/cjieba/archive/refs/tags/v$(version).tar.gz",
        "1f5ca82c5d19c38485c8fd50db8711602d339b1e85f15fb864fc116c7f770f12"
    )
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir $libdir $prefix/share
curl https://raw.githubusercontent.com/yanyiwu/cppjieba/master/LICENSE > LICENSE
install_license LICENSE 
cd cjieba-0.3.0/
g++ -o "$libdir/libcjieba.$dlext" lib/jieba.cpp -shared -fPIC -I./deps/ -std=c++11
cp -a dict $prefix/share/
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libcjieba", :libcjieba),
    FileProduct("share/dict/hmm_model.utf8", :hmm_model),
    FileProduct("share/dict/idf.utf8", :idf),
    FileProduct("share/dict/jieba.dict.utf8", :jiebadict),
    FileProduct("share/dict/stop_words.utf8", :stopwords),
    FileProduct("share/dict/user.dict.utf8", :userdict)
]

dependencies = Dependency[
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6"
)
