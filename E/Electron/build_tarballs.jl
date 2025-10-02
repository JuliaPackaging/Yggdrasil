using BinaryBuilder

name = "Electron"
version = v"38.2.0"

url_prefix = "https://github.com/electron/electron/releases/download/v$version/electron-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.zip", "f0028975282a6f2946797175ac406a95096f29c5dcda98048148668dfa36eff8"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.zip", "76116429b368c883f93eb98cbdb053f98d811c35943133fe3cf9b408018ebe2f"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.zip", "a4345bb87504b6b2bef29c0dc53b99770b203a7052fd2c5d38fd3e16177d3e68"; unpack_target = "arm-linux-gnueabihf"),

    ArchiveSource("$(url_prefix)-linux-x64.zip", "f0028975282a6f2946797175ac406a95096f29c5dcda98048148668dfa36eff8"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.zip", "76116429b368c883f93eb98cbdb053f98d811c35943133fe3cf9b408018ebe2f"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.zip", "a4345bb87504b6b2bef29c0dc53b99770b203a7052fd2c5d38fd3e16177d3e68"; unpack_target = "arm-linux-musleabihf"),

    ArchiveSource("$(url_prefix)-darwin-x64.zip", "232a83cb11b37f67dc0683402463ef30ac0309afb8e96f3bc1ea53e72fafa789"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.zip", "cff178e2cb9ae0d957d43009ef46d249d5594bc107d7704130bc0ce2e234bbd1"; unpack_target = "aarch64-apple-darwin20"),

    ArchiveSource("$(url_prefix)-win32-x64.zip", "4382b317dbbbc0bbf8a301304749324b88207218aac240b670f1c1247c2a02b0"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win32-ia32.zip", "b3bd0de05613ab5312013133de1587c35fdfa22e11e1f76fcaf6ea0248128f0c"; unpack_target = "i686-w64-mingw32"),
    # ArchiveSource("$(url_prefix)-win32-arm64.zip", "801e520e3ec8a0af1bdab5110846def06af3f427267351eb3c4359a00cd1294e"; unpack_target = "aarch64-w64-mingw32"),  # Not supported by BinaryBuilder
]

script = raw"""
cd ${WORKSPACE}/srcdir/${target}

if [[ "${target}" == *-mingw* ]]; then
    # Windows structure
    install -Dvm 0755 "electron.exe" "${bindir}/electron${exeext}"

    # Copy all necessary DLLs and resources
    cp -r resources "${prefix}/resources"
    for dll in *.dll; do
        if [[ -f "$dll" ]]; then
            install -Dvm 0755 "$dll" "${bindir}/$dll"
        fi
    done

    # Copy additional files
    if [[ -f "LICENSE" ]]; then
        install_license LICENSE
    elif [[ -f "LICENSES.chromium.html" ]]; then
        install_license LICENSES.chromium.html
    fi
    if [[ -f "version" ]]; then
        cp "version" "${prefix}/version"
    fi
elif [[ "${target}" == *-apple-* ]]; then
    # macOS structure - Electron.app bundle
    if [[ -d "Electron.app" ]]; then
        cp -r Electron.app "${prefix}/Electron.app"
        # Create a wrapper script
        mkdir -p "${bindir}"
        cat > "${bindir}/electron" << 'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DIR/Electron.app/Contents/MacOS/Electron" "$@"
EOF
        chmod +x "${bindir}/electron"
    fi

    if [[ -f "LICENSE" ]]; then
        install_license LICENSE
    elif [[ -f "LICENSES.chromium.html" ]]; then
        install_license LICENSES.chromium.html
    fi
else
    # Linux structure
    install -Dvm 0755 "electron" "${bindir}/electron${exeext}"

    # Copy all necessary shared libraries and resources
    cp -r resources "${prefix}/resources"
    for so in *.so*; do
        if [[ -f "$so" ]]; then
            install -Dvm 0755 "$so" "${libdir}/$so"
        fi
    done

    # Copy additional files
    if [[ -f "LICENSE" ]]; then
        install_license LICENSE
    elif [[ -f "LICENSES.chromium.html" ]]; then
        install_license LICENSES.chromium.html
    fi
    if [[ -f "version" ]]; then
        cp "version" "${prefix}/version"
    fi
    if [[ -d "locales" ]]; then
        cp -r locales "${prefix}/locales"
    fi
fi
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="glibc", cxxstring_abi="cxx11"),

    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="musl", cxxstring_abi="cxx11"),

    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),

    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    # Platform("aarch64", "windows"),  # Not supported by BinaryBuilder
]

products = Product[
    ExecutableProduct("electron", :electron),
]

# macOS and Windows: Self-contained, only link to OS frameworks/DLLs
# Linux: Requires X11, GTK3, audio, and other GUI libraries
linux_platforms = filter(Sys.islinux, platforms)

dependencies = [
    # X11 dependencies (Linux only)
    Dependency("Xorg_libX11_jll"; platforms=linux_platforms),
    Dependency("Xorg_libXext_jll"; platforms=linux_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=linux_platforms),
    Dependency("Xorg_libXdamage_jll"; platforms=linux_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=linux_platforms),
    Dependency("Xorg_libXcomposite_jll"; platforms=linux_platforms),
    Dependency("Xorg_libxcb_jll"; platforms=linux_platforms),

    # GTK and related (Linux only)
    Dependency("GTK3_jll"; platforms=linux_platforms),
    Dependency("Glib_jll"; platforms=linux_platforms),
    Dependency("Pango_jll"; platforms=linux_platforms),
    Dependency("Cairo_jll"; platforms=linux_platforms),
    Dependency("at_spi2_atk_jll"; platforms=linux_platforms),
    Dependency("at_spi2_core_jll"; platforms=linux_platforms),
    Dependency("ATK_jll"; platforms=linux_platforms),

    # Audio (Linux only)
    Dependency("alsa_jll"; platforms=linux_platforms),

    # Other Linux dependencies
    Dependency("Dbus_jll"; platforms=linux_platforms),
    Dependency("Expat_jll"; platforms=linux_platforms),
    Dependency("xkbcommon_jll"; platforms=linux_platforms),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10")
