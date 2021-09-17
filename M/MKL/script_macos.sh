
sha256() { sha256sum "$1" | awk '{ print $1 }'; }

exists() {
  if [ "$2" != in ]; then
    echo "Incorrect usage.  Use: exists {key} in {array}"
    return
  fi
  eval '[ ${'$3'[$1]+x} ]'
}

cd ${WORKSPACE}/srcdir/mkl-${target}/lib

#####
## Replace duplicate library files with symlinks
## (https://github.com/JuliaPackaging/Yggdrasil/issues/3632)

declare -A SHAs

# Iterate over files in reverse order of name length.
# This ensures any symlinks go to the longer name.
for file in $(find . -type f | awk '{ print length, $0 }' | sort -n -r | cut -d" " -f2-); do
    sha=$(sha256 "$file")

    if ! exists $sha in SHAs; then
        SHAs[$sha]="$file"
        continue
    fi

    src_file="${SHAs[$sha]}"
    ln -sf $src_file $file
done

#####

cd ..
cp -r lib/* ${libdir}
install_license info/licenses/*.txt