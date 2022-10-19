#!/bin/bash
# configure basic settings, will prompt for input

echo "----- GIT Global Config, Name and Email -------------"
read -p 'Name for GIT (leave blank to skip): ' git_name
if [[ ! -z "$git_name" ]]; then
    echo 'Setting git name'
    git config --global user.name "$git_name"
else
    echo 'Skipping'
fi

read -p 'Email for GIT (leave blank to skip): ' git_email
if [[ ! -z "$git_email" ]]; then
    echo 'Setting git email'
    git config --global user.email "$git_email"
else
    echo 'Skipping'
fi

# ----------------------------------------------------------

echo "----- User Groups (requires sudo) -------------------"
read -p 'Add yourself to "www-data" group? [y/N]: ' add_www
case $add_www in
    [Yy]* )
        echo 'Adding to group'
        sudo usermod -a -G www-data `whoami`
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Add gittree alias to ~/.bashrc ----------------"
read -p 'Add "alias gittree"? [y/N]: ' add_alias
case $add_alias in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'TERM'

# ABS gittree alias
alias gittree='git log --all --decorate --oneline --graph'

TERM
) >> "$HOME/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Auto save screen layout? edits ~/.screenrc ----"
read -p 'Add "layour save default" to screen config? [y/N]: ' add_layout
case $add_layout in
    [Yy]* )
        echo 'Appending ~/.screenrc'
        (
        cat << 'TERM'

# ABS detach and re-attach without losing layout
layout save default

TERM
) >> "$HOME/.screenrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------
#
#echo "----- Append default TERM to ~/.bashrc --------------"
#read -p 'Add "export TERM=screen-256color"? [y/N]: ' add_term
#case $add_term in
#    [Yy]* )
#        echo 'Appending ~/.bashrc'
#        (
#        cat << 'TERM'
#
## ABS set term to something reasonable
#export TERM=screen-256color
#
#TERM
#) >> "$HOME/.bashrc"
#        ;;
#    * )
#        echo 'Skipping'
#        ;;
#esac
#
# ----------------------------------------------------------

echo "----- Install vim configuration ---------------------"
read -p 'Setup vim, colors, defaults, etc? [y/N]: ' set_vim
case $set_vim in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'VIM'

# ABS default to using vim
export EDITOR=vim
export VISUAL=vim

VIM
) >> "$HOME/.bashrc"

        echo 'Installing vim color "colorful256"'
        mkdir -p "${HOME}/.vim/colors"
        LOCATION=`dirname "$0"`
        cp "${LOCATION}/vim/colorful256.vim" "${HOME}/.vim/colors/colorful256.vim"

	echo 'Installing vimrc'
	if [ -f "${HOME}/.vimrc" ]; then
	    echo 'existing vimrc file detected, backing up'
	    mv "${HOME}/.vimrc" "${HOME}/.vimrc_`date +%s`"
	fi
        cp "${LOCATION}/vim/vimrc" "${HOME}/.vimrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Install GoAccess configuration ----------------"
read -p 'Add GoAccess RC config file? [y/N]: ' set_gorc
case $set_gorc in
    [Yy]* )
        echo 'Installing GoAccess RC'
        LOCATION=`dirname "$0"`
        cp "${LOCATION}/conf/goaccessrc" "${HOME}/.goaccessrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Download Git Prompt Script --------------------"
read -p 'Add git prompt to bash config? [y/N]: ' set_prompt
case $set_prompt in
    [Yy]* )
        echo 'Downloading Git Prompt'
        LOCATION=`dirname "$0"`
        [ ! -d "${HOME}/bin" ] && mkdir "${HOME}/bin"
        wget 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh' -O "${HOME}/bin/git-prompt.sh" -q && ( cat << 'PROMPT'

# ABS git prompt
source ~/bin/git-prompt.sh

PROMPT
) >> "${HOME}/.bashrc"
        chmod +x "${HOME}/bin/git-prompt.sh"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Append prompt style to ~/.bashrc --------------"
read -p 'Add prompt style to bash config? [y/N]: ' add_style
case $add_style in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'STYLE'

# ABS prompt color
if [ "$(type -t __git_ps1)" == 'function' ]; then
    PS1='\[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\[\e[33m\]\w\[\e[m\]$(__git_ps1 "\e[m\](\e[35m\]%s\e[m\])")\e[m\]\\$ '
else
    PS1="\[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\[\e[33m\]\w\[\e[m\]\\$ "
fi

STYLE
) >> "$HOME/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Done ------------------------------------------"
echo "to take effect now, you need to run:"
echo "source ~/.bashrc"

