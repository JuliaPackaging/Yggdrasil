use_apk()
{
    echo "You tried to run '$1', but the package manager is 'apk'; try running 'apk add <package name>' instead!" >&2
    return 1
}

# Help users to figure out which package manager to use
alias apt="use_apk apt"
alias yum="use_apk yum"
alias pacman="use_apk pacman"
