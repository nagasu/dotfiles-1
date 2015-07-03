#!/bin/bash

export PLATFORM

# Gerenal utilities {{{1
e_newline() {
    printf "\n"
}

e_header() {
    printf " \033[37;1m%s\033[m\n" "$*" 1>&2
}

e_error() {
    printf " \033[31;4m%s\033[m\n" "✖ $*" 1>&2
}

e_done() {
    printf " \033[37;1m%s\033[m...\033[32mOK\033[m\n" "✔ $*" 1>&2
}

is_exists() {
    which "$1" >/dev/null 2>&1
    return $?
}

has() {
    is_exists "$@"
}

die() {
    e_error "Error: $1"
    exit "${2:-1}"
}

is_login_shell() { [[ $SHLVL == 1 ]]; }

is_git_repo() { git rev-parse --is-inside-work-tree &>/dev/null; }

is_screen_running() {
    [ ! -z "$STY" ]
}

is_tmux_runnning() {
    [ ! -z "$TMUX" ]
}

is_screen_or_tmux_running() {
    is_screen_running || is_tmux_runnning
}

shell_has_started_interactively() {
    [ ! -z "$PS1" ]
}

is_ssh_running() {
    [ ! -z "$SSH_CONECTION" ]
}

ostype() {
    uname | lower
}

os_detect() {
    export PLATFORM
    case "$(ostype)" in
        *'linux'*)  PLATFORM='linux'   ;;
        *'darwin'*) PLATFORM='osx'     ;;
        *'bsd'*)    PLATFORM='bsd'     ;;
        *)          PLATFORM='unknown' ;;
    esac
}

is_osx() {
    os_detect
    if [ "$PLATFORM" = "osx" ]; then
        return 0
    else
        return 1
    fi
}

is_linux() {
    os_detect
    if [ "$PLATFORM" = "linux" ]; then
        return 0
    else
        return 1
    fi
}

is_bsd() {
    os_detect
    if [ "$PLATFORM" = "bsd" ]; then
        return 0
    else
        return 1
    fi
}

get_os() {
    local os
    for os in osx linux bsd; do
        if is_$os; then
            echo $os
        fi
    done
}

noecho() {
    if [ "$(echo -n)" = "-n" ]; then
        echo "${*:-> }\c"
    else
        echo -n "${@:-> }"
    fi
}

lower() {
    tr "[:upper:]" "[:lower:]"
}

upper() {
    tr "[:lower:]" "[:upper:]"
}

# Dotfiles {{{1

DOTFILES=~/.dotfiles; export DOTFILES
DOTFILES_GITHUB="https://github.com/b4b4r07/dotfiles.git"; export DOTFILES_GITHUB

# shellcheck disable=SC1078,SC1079,SC2016
dotfiles_logo='
    | |     | |  / _(_) |           
  __| | ___ | |_| |_ _| | ___  ___  
 / _` |/ _ \| __|  _| | |/ _ \/ __| 
| (_| | (_) | |_| | | | |  __/\__ \ 
 \__,_|\___/ \__|_| |_|_|\___||___/ 

*** WHAT IS INSIDE? ***
  1. Download https://github.com/b4b4r07/dotfiles.git
  2. Symlinking dot files to your home directory
  3. Execute all sh files within `etc/init/` (optional)

See the README for documentation.
https://github.com/b4b4r07/dotfiles

Copyright (c) 2014 "BABAROT" aka @b4b4r07
Licensed under the MIT license.
'

dotfiles_download() {
    is_debug() {
        if [ "$DEBUG" = 1 ]; then
            return 0
        else
            return 1
        fi
    }

    if [ -d "$DOTFILES" ]; then
        die "$DOTFILES: already exists"
    fi

    e_newline
    e_header "Downloading dotfiles..."

    if is_debug; then
        :
    else
        if is_exists "git"; then
            # --recursive equals to ...
            # git submodule init
            # git submodule update
            git clone --recursive "$DOTFILES_GITHUB" "$DOTFILES"

        elif is_exists "curl" || is_exists "wget"; then
            # curl or wget
            local tarball="https://github.com/b4b4r07/dotfiles/archive/master.tar.gz"
            if is_exists "curl"; then
                curl -L "$tarball"

            elif is_exists "wget"; then
                wget -O - "$tarball"

            fi | tar xv -
            mv -f dotfiles-master "$DOTFILES"

        else
            die "curl or wget required"

        fi
    fi &&

        e_newline && e_done "Download"
}

dotfiles_deploy() {
    e_newline
    e_header "Deploying dotfiles..."

    if [ ! -d $DOTFILES ]; then
        die "$DOTFILES: not found"
    fi

    cd "$DOTFILES"

    if is_debug; then
        :
    else
        if make deploy; then
            e_success "done"
        fi
    fi &&

        e_newline && e_done "Deploy"
}

dotfiles_initialize() {
    e_newline
    e_header "Initializing dotfiles..."

    if is_debug; then
        :
    else
        if [ -f Makefile ]; then
            make init
        else
            die "Makefile: not found"
        fi
    fi &&

        e_newline && e_done "Initialize"
}

# A script for the file named "install"
dotfiles_install() {
    ### 1. Download the repository
    ### ==> downloading
    ###
    ### Priority: git > curl > wget
    dotfiles_download &&

    ### 2. Deploy dotfiles to your home directory
    ### ==> deploying
    dotfiles_deploy &&

    ### 3. Execute all sh files within etc/init/
    ### ==> initializing
    dotfiles_initialize "$@"
}

if echo "$-" | grep -q "i"; then
    # -> source a.sh
    : return
else
    trap "e_error 'terminated'; exit 1" INT ERR

    # three patterns
    # -> cat a.sh | bash
    # -> bash -c "$(cat a.sh)"
    # -> bash a.sh
    if [ "$0" = "${BASH_SOURCE:-}" ]; then
        # -> bash a.sh
        exit
    fi

    # -> cat a.sh | bash
    # -> bash -c "$(cat a.sh)"
    echo "$dotfiles_logo"
    dotfiles_install "$@"
fi

# __END__ {{{1
#vim:fdm=marker
