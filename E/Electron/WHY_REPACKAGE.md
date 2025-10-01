# Why We Repackage Electron Instead of Building from Source

An essay by Claude.

## TL;DR

Building Electron from source is **impractical for Yggdrasil** due to extreme complexity, resource requirements, and minimal benefits. Repackaging official prebuilt binaries is the standard approach used by distributions worldwide.

## The Reality of Building Electron from Source

### 1. **Massive Resource Requirements**

According to Electron's official documentation:

- **Disk Space**: ~100GB+ (gclient sync downloads entire Chromium)
- **RAM**: 16GB minimum, 32GB+ recommended
- **Build Time**: 4-8+ hours on modern hardware
- **CPU**: Intensive compilation of millions of lines of code

The docs literally say: "This will take a while, go get a coffee" ☕

### 2. **Complex Build System**

Electron's build requires:

```bash
# Install depot_tools (Chromium's build tools)
gclient config --name "src/electron" --unmanaged https://github.com/electron/electron
gclient sync --with_branch_heads --with_tags  # Downloads ~16GB of dependencies
export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools
gn gen out/Release --args="import(\"//electron/build/args/release.gn\")"
ninja -C out/Release electron  # Hours of compilation
```

This involves:
- **depot_tools**: Google's custom source management tools
- **GN**: Meta-build system that generates Ninja files
- **Ninja**: High-performance build system
- **Chromium source**: One of the largest codebases in existence
- **Node.js integration**: Complex C++/JavaScript binding layer

### 3. **Platform-Specific Nightmares**

**macOS:**
- Requires specific Xcode versions
- Needs macOS SDKs
- Code signing complexities
- Framework bundle creation

**Windows:**
- Requires Visual Studio (specific versions)
- Windows SDK dependencies
- `DEPOT_TOOLS_WIN_TOOLCHAIN` environment variable magic
- Visual C++ runtime considerations

**Linux:**
- Multiple distribution-specific dependencies
- System library version conflicts
- Different C++ ABIs (cxx03 vs cxx11)

### 4. **BinaryBuilder Limitations**

BinaryBuilder is designed for typical open-source projects, not Chromium-scale builds:

❌ **Sandboxed Environment**: Can't easily download hundreds of dependencies during build
❌ **Build Platform**: Only x86_64-linux-musl, but Chromium expects native builds
❌ **Time Limits**: Multi-hour builds would timeout
❌ **Memory Constraints**: Chromium needs massive amounts of RAM
❌ **Network Access**: Limited during build, but gclient needs extensive downloads
❌ **Cross-Compilation**: Chromium's cross-compilation is extremely complex

### 5. **Maintenance Nightmare**

Building from source would require:

- Tracking Chromium's rapidly changing build requirements
- Managing platform-specific compiler versions
- Debugging obscure build failures
- Updating build scripts for every Electron release
- Dealing with dependency version conflicts
- Hours of CI/CD time for each build

### 6. **Industry Standard: Repackaging**

**Who repackages instead of building:**

✅ **Major Linux Distributions**: Debian, Ubuntu, Fedora, Arch (most just repackage)
✅ **Snap/Flatpak**: Use official Electron binaries
✅ **Package Managers**: npm, yarn, pnpm all download prebuilt binaries
✅ **Electron Apps**: VS Code, Slack, Discord, etc. all use prebuilt Electron
✅ **Yggdrasil Precedent**: NodeJS packages also repackage prebuilt binaries

**Who builds from source:**

❌ Only Electron core developers and a few advanced users with specific needs

## Benefits of Repackaging

### ✅ Advantages

1. **Reliability**: Official binaries are well-tested
2. **Speed**: Minutes vs hours/days of building
3. **Disk Usage**: ~300MB downloaded vs ~100GB+ for source
4. **Security**: Official builds receive security patches
5. **Reproducibility**: Consistent SHA256 checksums
6. **Maintenance**: Just update version number and checksums
7. **Cross-Platform**: All platforms built by experts on native hardware

### ❌ Disadvantages

1. Trust in upstream binaries (mitigated by SHA256 verification)
2. Less customization (but Electron is configurable at runtime)
3. Dependency on upstream release schedule (acceptable for most use cases)

## What If We Really Wanted to Build from Source?

If you absolutely needed to build Electron from source for Yggdrasil, here's what it would require:

### Step 1: Prepare the Build Environment (Days of work)
```julia
# This would need to be added to the recipe
script = raw"""
# Install depot_tools
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"

# Setup build directory
mkdir electron-build && cd electron-build
gclient config --name "src/electron" --unmanaged https://github.com/electron/electron

# This downloads ~16GB and takes hours
gclient sync --with_branch_heads --with_tags

cd src
export CHROMIUM_BUILDTOOLS_PATH=`pwd`/buildtools

# Generate build files
gn gen out/Release --args="import(\"//electron/build/args/release.gn\") target_cpu=\"${target_arch}\""

# Build (takes 4-8+ hours)
ninja -C out/Release electron

# Extract and package the result
...
"""
```

### Step 2: Handle Cross-Compilation (Weeks of work)
- Chromium's cross-compilation is experimental and poorly documented
- Would need custom toolchains for each target
- Many platform-specific patches required

### Step 3: Ongoing Maintenance (Continuous effort)
- Every Electron update might break the build
- Chromium changes rapidly
- Platform-specific issues would arise constantly

### Estimated Effort

- **Initial Setup**: 2-4 weeks of full-time development
- **Per-Version Update**: 1-3 days testing and fixing
- **Build Time**: 4-8+ hours per platform per build
- **Success Rate**: Probably 60-70% without extensive testing

## Conclusion

**Repackaging is the right choice.** It's:
- Industry standard ✅
- Faster ✅
- More reliable ✅
- Easier to maintain ✅
- What users expect ✅

Building from source would be an interesting technical challenge, but would provide minimal practical benefit for Yggdrasil users while consuming enormous resources.

## References

- [Electron Build Instructions](https://www.electronjs.org/docs/latest/development/build-instructions-gn)
- [Chromium Build Instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md)
- [NodeJS Yggdrasil Recipes](https://github.com/JuliaPackaging/Yggdrasil/tree/master/N/NodeJS) - Also repackage prebuilt binaries
