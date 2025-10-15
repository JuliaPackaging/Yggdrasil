using BinaryBuilder, Pkg

name = "LlamaCppOutlines"
version = v"1.1.0"

sources = [
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/x86_64-linux-gnu-cpu.tar.gz",
                  "5f13842471815f9eec77e688df1285edbfd59b4f6fcf32a9b1a5e7e431bf26c4"),
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/x86_64-linux-gnu-cuda.tar.gz",
                  "d2f88f47f7326ef5f9eb4d576a7c39548eb01248f4823029779b067b3f4cef9d"),
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/x86_64-w64-mingw32-cpu.zip",
                  "08034e8747293d0fcaaa0ab2d5d6f0328b0c38bb7e79174927403b31602e4f0d"),
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/x86_64-w64-mingw32-cuda.zip",
                  "a54c8832d1fd53aa94a4d1640f7c13d251b7387f4a86619e1e1e06db6bd7a7ea"),
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/x86_64-apple-darwin-metal.tar.gz",
                  "4f5a35cbfd2a960749ce429d600c1f991419eb174e3684181fb01dbaf6ea2194"),
    ArchiveSource("https://github.com/krishnaveti/LlamaCppOutlines_jll.jl/releases/download/v1.1.0/aarch64-apple-darwin-metal.tar.gz",
                  "0d8b0173e2005e32948d1a7d2b4135600181c14cf0af8bbcda6c452182f82ec0"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

# Install license
if [ ! -f LICENSE ]; then
    cat > LICENSE << 'EOL'
MIT License

Copyright (c) 2025 LlamaCppOutlines Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOL
fi
install_license LICENSE

# Create destination directories
mkdir -p ${libdir}
mkdir -p ${bindir}
mkdir -p ${includedir}

# Copy files based on platform
if [[ "${target}" == *"mingw"* ]]; then
    # Windows: DLLs are in bin/
    if [ -d bin ]; then
        find bin -name "*.dll" -exec cp {} ${libdir}/ \;
        find bin -name "*.exe" -exec cp {} ${bindir}/ \;
        find bin -name "*.py" -exec cp {} ${bindir}/ \;
    fi
    if [ -d lib ]; then
        find lib -name "*.lib" -exec cp {} ${libdir}/ \;
    fi
else
    # Linux and macOS: Standard layout
    if [ -d lib ]; then
        cp -r lib/* ${libdir}/
    fi
    if [ -d bin ]; then
        cp -r bin/* ${bindir}/
    fi
fi

# Copy headers
if [ -d include ]; then
    cp -r include/* ${includedir}/
fi

# Set permissions
chmod +x ${libdir}/* 2>/dev/null || true
chmod +x ${bindir}/* 2>/dev/null || true
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc", cuda="12"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "windows"; cuda="12"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

products = [
    ExecutableProduct("llama-cli", :llama_cli),
    ExecutableProduct("llama-server", :llama_server),
    ExecutableProduct("llama-quantize", :llama_quantize),
    ExecutableProduct("llama-embedding", :llama_embedding),
    ExecutableProduct("llama-perplexity", :llama_perplexity),
    ExecutableProduct("llama-bench", :llama_bench),
    ExecutableProduct("llama-run", :llama_run),
    ExecutableProduct("llama-simple", :llama_simple),
    ExecutableProduct("llama-gguf", :llama_gguf),
    ExecutableProduct("llama-tokenize", :llama_tokenize),
    ExecutableProduct("llama-imatrix", :llama_imatrix),
    LibraryProduct(["libllama", "llama"], :libllama),
    LibraryProduct(["liboutlines_core", "outlines_core"], :liboutlines_core),
    LibraryProduct(["libggml", "ggml"], :libggml),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")