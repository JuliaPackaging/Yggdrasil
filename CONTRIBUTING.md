# Contributing to Yggdrasil

## Information for contributors

Yggdrasil is a collection of recipes to build binary packages, saved in files called `build_tarballs.jl`.

If you are new to BinaryBuilder, please read [its documentation](https://docs.binarybuilder.org/stable/).
In particular, the section [Project flow](https://docs.binarybuilder.org/stable/#Project-flow) presents different ways you can use BinaryBuilder to create a new `build_tarballs.jl` script or edit an existing one.
Note that the wizard is a convenient tool to get started with BinaryBuilder, but it does not give you access to all the options you can use in a manual `build_tarball.jl` file.
Also, for an already existing recipe you are advised to edit it manually rather than starting from scratch with the wizard.

If you want to submit a new package or update an existing one, you always have to open a pull request to the [Yggdrasil repository](https://github.com/JuliaPackaging/Yggdrasil/) on GitHub to create or modify the `build_tarballs.jl` file of the package you are interested in.
Note that it is important to modify the `build_tarballs.jl` file of your package, or any other file in the same directory or one of its subdirectories: Yggdrasil CI workflow uses the modified `build_tarballs.jl` file to identify which package to rebuild, if no `build_tarballs.jl` (or any other file in its subdirectories) is touched, no build will happen.
Make sure not to mistype the name of the file.

If you are submitting a recipe for a new package, follow the suggestions in the [Building Packages](https://docs.binarybuilder.org/stable/building/) page of BinaryBuilder documentation.

If you want to build a new version of an existing package, you can open a pull request which updates the sources and the version number of the package as appropriate.
In most cases it is sufficient to change only these two properties of the recipe, but sometimes more work will be required if there are any changes in the build system (e.g. changed dependencies, or options for the build system) or bugs in the source code to deal with.

### Update version of an existing recipe

If you want to build a newer version of an existing recipe, in the first instance you only need to update in the `build_tarballs.jl` script of the package of your interest the version number and the source (you will likely need to update URL and checksum, for an `ArchiveSource`, or the Git revision for a `GitSource`).
Other things you may need to change include:

* the build script, in case the build system changed in the newer version;
* the list of dependencies, in case the newer version requires more or fewer dependencies;
* the compatibility bounds with some of the dependencies, in case the package bumped their required versions.

Other changes may be required on a case-by-case basis, depending on the success to build the newer version.

### Compatibility tips

When building binary packages we have to deal with [several incompatibilities](https://docs.binarybuilder.org/stable/tricksy_gotchas/).
As a general remark, when using GCC as compiler (which is default when targeting Linux and Windows platforms) try to use the ***oldest*** versions that is able to compile your code, which can be selected with the `preferred_gcc_version` keyword argument to the [`build_tarballs`](https://docs.binarybuilder.org/stable/reference/#BinaryBuilder.build_tarballs) function, especially for [C++ code](https://gcc.gnu.org/onlinedocs/libstdc++/manual/abi.html), this is the only way to get maximum compatibility.
In any case, avoid using GCC 11+ when building C++, as that would be incompatible with Julia v1.6, the current Long Term Support version.
There are currently no such problems with LLVM (the default compiler framework used when targeting macOS and FreeBSD), so that you can generally use the latest version of LLVM available, which is already the default.

### Recommendations and tips about commit messages

Yggdrasil is a collection of recipes for hundreds of different packages.
To make it easier to browse through commits history and list of pull requests, please use descriptive commit messages and include in the title of the commit and of pull requests the name of the package you are touching, [for example](https://github.com/JuliaPackaging/Yggdrasil/pull/6074):

```
[XGBoost] Update to v1.7.3
```

Titles like

```
Update build_tarballs.jl
```

or

```
Build v1.7.3
```

are not descriptive (virtually all pull requests update a file called `build_tarballs.jl`) or they do not make it clear what package they refer to.

#### Special keywords in commit messages

Anywhere in a commit message you can use the special keyword `[skip build]`, which has a two-fold effect:

* in pull requests, a build of the touched packages will not be performed
* for commits pushed to the default branch, a new build of the touched packages will not be performed but a new version of the correspoding JLL packages will be published, using as artifacts those from the latest registered versions of the packages (the build number will be increased by one).

### Understanding build cache on Yggdrasil

On Yggdrasil we run hundreds of builds every day.
To minimise build times, we have a complex building infrastructure to cache as many build artifacts as possible:

* BinaryBuilder uses by default [`ccache`](https://ccache.dev/) to cache compilers artifacts where possible;
* on Yggdrasil we cache all successful builds, to avoid rebuilding packages unneedlessly.
  This cache in indexed by:

  * the git tree hash of the directory where the `build_tarballs.jl` file is
  * the hash of the [`.ci/Manifest.toml`](.ci/Manifest.toml) file.

This means that if you trigger a build which changes neither of them after a successful run, then a build will not actually happen.
For this reason, please ***refrain from running builds which only rebase/merge your branch on the default branch*** after a fully successful build: there will be no build log, and reviewers will have a much harder time than necessary to find the audit logs.
These rebuilds are also completely useless, as the build artifacts will in most cases be [bit-by-bit identical](https://docs.binarybuilder.org/stable/#Reproducibility) to the previous ones, only causing waste of time, resources, and energy.

### Branch naming

This is not specific to contributing to Yggdrasil, but as a general remark working with Git and GitHub, opening a PR from a branch with the same name as the target branch is an [anti-pattern](https://blog.jasonmeridth.com/posts/do-not-issue-pull-requests-from-your-master-branch/).
You should always keep the target branch (e.g. `main`, `master`) in your fork in-sync with the branch with the same name in the upstream repository, and then create a new branch out of the target branch for each pull request you want to open.
This is particularly important to keep history of your pull requests simple and readable and avoid creating noise which unnecessarily complicates the review process.

## Information for maintainers

Here are some recommendations for Yggdrasil maintainers:

* before merging a pull request, make sure the log of the build does not contain important warnings or error messages such as
  * missing license file.  This is reported as an error in CI log during audit but it is not as a fatal error which would prevent successful build
  * "Linked library `<LIBRARY NAME>` could not be resolved and could not be auto-mapped"
* make sure a pull request is not changing julia compat bounds without changing the version number of the package
  This is particularly important when building an existing package for the first time for [aarch64-darwin or armv6l-linux](https://github.com/JuliaPackaging/Yggdrasil/issues/2763)
* make sure dependencies of [packages with known incompatibilities](https://github.com/JuliaPackaging/Yggdrasil/issues/3024) are pinned correctly
* always [squash and merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/about-pull-request-merges#squash-and-merge-your-commits) pull requests, to keep history short and linear.
  There is little need to preserve full history of individual pull requests.
  This also makes sure special keywords in commit messages are part of the commit which triggers the CI workflow and so they can have effect
* use special commit message keywords as appropriate:
  * `[skip ci]` to not run CI at all when merging a pull request
  * `[skip build]` to only update the JLL wrapper of a package without rebuilding the package once again
