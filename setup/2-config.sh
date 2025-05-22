#!/usr/bin/env bash

called_backup=false
curdate=$(date '+%Y-%m-%d')
script_dir=$(dirname "$0")
# absolute path to this scripts parent directory (package root)
package_dir=$(readlink -f "$0" | xargs dirname | xargs dirname)

# ----------------------------------------------------------

# call this function before editing bashrc, will only make backup if needed
function make_bashrc_backup () {
    if [ "${called_backup}" = false ]; then
        called_backup=true
        if [[ ! -f "${HOME}/bashrc.backup.${curdate}" ]]; then
            echo 'backing up existing bashrc'
            cp "${HOME}/.bashrc" "${HOME}/bashrc.backup.${curdate}"
        fi
    fi
}

# ----------------------------------------------------------

read -p 'Install git-prompt and include in ~/.bashrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        ( cat << BASHRC

# ABS include git prompt
source ${package_dir}/git-prompt.sh

BASHRC
) >> "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Use colorful prompt style to ~/.bashrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        ( cat << 'BASHRC'

# ABS prompt color
abs_user="\[\e[31m\]\u"                  # username (red)
abs_host="\[\e[m\]@\[\e[36m\]\h"         # hostname (teal)
abs_work="\[\e[m\]:\[\e[33m\]\w"         # work-dir (yellow)
abs_git="\[\e[m\](\[\e[35m\]%s\[\e[m\])" # branch   (purple)
abs_tail="\[\e[34m\]\$\[\e[m\] "         # $ or #   (blue)
if [[ -f "$HOME/.sudo_as_admin_successful" ]] || [[ "0" == $(id -u) ]]; then
    abs_user="\[\e[32m\]\u" # username (green) if sudo/root
fi

if [ "$(type -t __git_ps1)" == 'function' ]; then
    PROMPT_COMMAND="__git_ps1 \"$abs_user$abs_host$abs_work\" \"$abs_tail\" \"$abs_git\""
else
    PS1="$abs_user$abs_host$abs_work$abs_tail"
fi

BASHRC
) >> "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

git_name=$(git config --global user.name)
read -p "Name for GIT (blank to leave unaltered), currently '${git_name}': " response
if [[ ! -z "${response}" ]]; then
    git config --global user.name "${response}"
else
    echo 'Skipping'
fi
echo ''

# ----------------------------------------------------------

git_email=$(git config --global user.email)
read -p "Email for GIT (blank to leave unaltered), currently '${git_email}': " response
if [[ ! -z "${response}" ]]; then
    git config --global user.email "${response}"
else
    echo 'Skipping'
fi
echo ''

# ----------------------------------------------------------

read -p 'Set GIT pager to display short output directly? [y/N]: ' response
case "${response}" in
    [Yy]* )
        git config --global core.pager "less -X -F"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Set GIT default branch name to "main"? [y/N]: ' response
case "${response}" in
    [Yy]* )
        git config --global init.defaultBranch main
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Add GIT alias "gittree"? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        ( cat << 'TERM'

# ABS gittree alias
alias gittree='git log --all --decorate --oneline --graph'

TERM
) >> "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Set "cd" to resolve symbolic directories in ~/.bashrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        ( cat << 'TERM'

# ABS when changing directory through a symlink, resolve real location
alias cd='cd -P'

TERM
) >> "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Set "ssh" symlink to "ssh-ident"? (and set python3 as python) [y/N]: ' response
case "${response}" in
    [Yy]* )
        sudo apt install python-is-python3 -y
        if [[ ! -f "${script_dir}/../ssh" ]]; then
            ln -s './ssh-ident' "${script_dir}/../ssh"
        fi
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Setup improved shell history? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
	# disable any existing history config
        sed -i -e '/^\(HISTCONTROL\|HISTFILESIZE\|HISTFILE\|HISTIGNORE\|HISTSIZE\|HISTTIMEFORMAT\|shopt -s histappend\|shopt -s histreedit\|shopt -s histverify\)/s/^/# ABS #/' "${HOME}/.bashrc"
        ( cat << 'BASHRC'

# ABS improved shell history
shopt -s histappend         # append to the history file, don't overwrite it
HISTSIZE=10000              # cache    the last  10,000 commands
HISTFILESIZE=100000         # remember the last 100,000 commands
HISTCONTROL="ignoredups"    # ignore duplicates
HISTIGNORE="l:la:ll:ls:cd:clear:history:pwd" # ignore select simple commands

# if we have already sourced this file, don't do it again
if [[ "${PROMPT_COMMAND}" != *"history"* ]]; then
    # append history as you go
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND/%;};}history -a"
fi

BASHRC
) >> "${HOME}/.bashrc"
        # update live config
        shopt -s histappend
        shopt -u histreedit
        shopt -u histverify
        export HISTSIZE=10000
        export HISTFILESIZE=100000
        export HISTCONTROL="ignoredups"
        export HISTIGNORE="l:la:ll:ls:cd:clear:history:pwd"
        if [[ "${PROMPT_COMMAND}" != *"history"* ]]; then
            export PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND/%;};}history -a"
        fi
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Set screen layout to autosave to ~/.screenrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        ( cat << 'SCREENRC'

# ABS detach and re-attach without losing layout
layout save default

SCREENRC
) >> "${HOME}/.screenrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Set VIM colors, config, and plugins? [y/N]: ' response
case "${response}" in
    [Yy]* )
        make_bashrc_backup
        if [[ -z $(command -v 'vim') ]] || [[ -z $(command -v 'curl') ]] || [[ -z $(command -v 'jq') ]]; then
            sudo apt install vim curl jq -y
        fi
        ( cat << 'BASHRC'

# ABS default to using vim
export EDITOR=vim
export VISUAL=vim
# ABS less to render tabs as 4 characters
export LESS=Rx4

BASHRC
) >> "${HOME}/.bashrc"

        if [[ -f "${HOME}/.vimrc" ]] && [[ ! -f "${HOME}/vimrc.backup.${curdate}" ]]; then
            mv "${HOME}/.vimrc" "${HOME}/vimrc.backup.${curdate}"
        fi

        [ ! -d "${HOME}/.vim/colors" ] && mkdir -p "${HOME}/.vim/colors"
        [ ! -d "${HOME}/.vim/autoload" ] && mkdir -p "${HOME}/.vim/autoload"

        # determine vim-plug latest version release tag
        version=$(curl --silent 'https://api.github.com/repos/junegunn/vim-plug/releases/latest' | jq -r '.tag_name')
        if [[ -z "$version" ]]; then
            # fallback to main branch if needed
            version="master"
        fi
        curl --output "${HOME}/.vim/autoload/plug.vim" --silent "https://raw.githubusercontent.com/junegunn/vim-plug/${version}/plug.vim"

        cp "${script_dir}/config/vim-vimrc" "${HOME}/.vimrc"
        cp "${script_dir}/config/vim-colors/*" "${HOME}/.vim/colors/"
        cp "${script_dir}/config/vim-autoload/*" "${HOME}/.vim/autoload/"

        vim +'PlugInstall --sync' +quitall
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

if [ "${called_backup}" = true ]; then
    echo -e "\e[33mremember some changes will not take effect until you run:"
    echo -e "\e[36msource ~/.bashrc\e[m"
    echo ''
fi

