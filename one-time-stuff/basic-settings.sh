#!/bin/bash
# configure basic settings, will prompt for input

# setup symlinks, if not installed in users bin directory
# need absolute path, so the symbolic links will be created correctly.
script_dir=$(readlink -f "$0" | xargs dirname | xargs dirname)

if [[ ! -d "$HOME/bin" ]]; then
    echo 'making personal bin directory'
    mkdir -p "$HOME/bin"
fi

# --- general scripts ---
if [[ ! -f "$HOME/bin/4-public-ip.sh" ]]; then
    echo 'installing 4-public-ip.sh'
    ln -s "$script_dir/4-public-ip.sh" "$HOME/bin/4-public-ip.sh"
fi

if [[ ! -f "$HOME/bin/6-public-ip.sh" ]]; then
    echo 'installing 6-public-ip.sh'
    ln -s "$script_dir/6-public-ip.sh" "$HOME/bin/6-public-ip.sh"
fi

if [[ ! -f "$HOME/bin/docker-ps.sh" ]]; then
    echo 'installing docker-ps.sh'
    ln -s "$script_dir/docker-ps.sh" "$HOME/bin/docker-ps.sh"
fi

if [[ ! -f "$HOME/bin/enumerate.sh" ]]; then
    echo 'installing enumerate.sh'
    ln -s "$script_dir/enumerate.sh" "$HOME/bin/enumerate.sh"
fi

if [[ ! -f "$HOME/bin/is-restart-needed.sh" ]]; then
    echo 'installing is-restart-needed.sh'
    ln -s "$script_dir/is-restart-needed.sh" "$HOME/bin/is-restart-needed.sh"
fi

if [[ ! -f "$HOME/bin/named-cat.sh" ]]; then
    echo 'installing named-cat.sh'
    ln -s "$script_dir/named-cat.sh" "$HOME/bin/named-cat.sh"
fi

if [[ ! -f "$HOME/bin/restart-if-needed.sh" ]]; then
    echo 'installing restart-if-needed.sh'
    ln -s "$script_dir/restart-if-needed.sh" "$HOME/bin/restart-if-needed.sh"
fi

if [[ ! -f "$HOME/bin/upgrade.sh" ]]; then
    echo 'installing upgrade.sh'
    ln -s "$script_dir/upgrade.sh" "$HOME/bin/upgrade.sh"
fi

# --- git related scripts ---
if [[ ! -f "$HOME/bin/fetch-all.sh" ]]; then
    echo 'installing fetch-all.sh'
    ln -s "$script_dir/fetch-all.sh" "$HOME/bin/fetch-all.sh"
fi

if [[ ! -f "$HOME/bin/list-all.sh" ]]; then
    echo 'installing list-all.sh'
    ln -s "$script_dir/list-all.sh" "$HOME/bin/list-all.sh"
fi

if [[ ! -f "$HOME/bin/pull-all.sh" ]]; then
    echo 'installing pull-all.sh'
    ln -s "$script_dir/pull-all.sh" "$HOME/bin/pull-all.sh"
fi

if [[ ! -f "$HOME/bin/status-all.sh" ]]; then
    echo 'installing status-all.sh'
    ln -s "$script_dir/status-all.sh" "$HOME/bin/status-all.sh"
fi

# ----------------------------------------------------------

# backup bashrc, but only the first run for the day
curdate=$(date '+%Y-%m-%d')
if [[ ! -f "$HOME/bashrc.backup.$curdate" ]]; then
    echo 'backing up existing bashrc'
    cp "$HOME/.bashrc" "$HOME/bashrc.backup.$curdate"
fi

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

STYLE
) >> "$HOME/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

read -p 'Set umask in your bashrc to prevent global access? [y/N]: ' set_umask
case $set_umask in
    [Yy]* )
        umask 0027
        echo 'Appending ~/.bashrc'
        (
        cat << 'TERM'

# ABS umask
umask 0027

TERM
) >> "$HOME/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

read -p 'Fix permissions of files already in your home directory? [y/N]: ' set_permissions
case $set_permissions in
    [Yy]* )
        chmod -R o-rwx "$HOME"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

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

read -p 'Set pager to display short output directly? [y/N]: ' set_pager
case $set_pager in
    [Yy]* )
        git config --global core.pager "less -X -F"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

read -p 'Set git default branch name to "main"? [y/N]: ' set_branch
case $set_branch in
    [Yy]* )
        git config --global init.defaultBranch main
        ;;
    * )
        echo 'Skipping'
        ;;
esac

read -p 'Enable git credential helper to cache? [y/N]: ' set_cache
case $set_cache in
    [Yy]* )
        git config --global credential.helper cache
        ;;
    * )
        echo 'Skipping'
        ;;
esac

## ----------------------------------------------------------
#
#echo "----- User Groups (requires sudo) -------------------"
#read -p 'Add yourself to "www-data" group? [y/N]: ' add_www
#case $add_www in
#    [Yy]* )
#        echo 'Adding to group'
#        sudo usermod -a -G www-data `whoami`
#        ;;
#    * )
#        echo 'Skipping'
#        ;;
#esac

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

echo "----- Set 'cd' to use physical directory structure -----"
read -p 'Add ``alias cd="cd -P"`` in ~/.bashrc? [y/N]: ' add_cd_alias
case $add_cd_alias in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'TERM'

# ABS when changing directory through a symlink, resolve real location
alias cd='cd -P'

TERM
) >> "$HOME/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Add symlink for ssh-ident as ssh --------------"
read -p 'Add "ssh alias for ssh-ident"? (also set python3 as python) [y/N]: ' add_ident
case $add_ident in
    [Yy]* )
        if [[ ! -f "$HOME/bin/ssh" ]]; then
            echo 'Creating ssh symlink to ssh-ident'
            ln -s "$script_dir/ssh-ident" "$HOME/bin/ssh"
        else
            echo 'home bin already has ssh, skipping'
        fi
        sudo apt install python-is-python3
        ;;
    * )
        echo 'Skipping'
        ;;
esac

# ----------------------------------------------------------

echo "----- Setup robust bash history? in ~/.bashrc -------"
read -p 'split bash history by terminal/screen in realtime? [y/N]: ' add_history
case $add_history in
    [Yy]* )
        if [[ -f "$HOME/.bash_history" ]]; then
            echo 'Comment existing history config'
            sed -i '/^\(HISTCONTROL\|HISTFILESIZE\|HISTFILE\|HISTIGNORE\|HISTSIZE\|HISTTIMEFORMAT\|shopt -s histappend\|shopt -s histreedit\|shopt -s histverify\)/s/^/# ABS #/' "$HOME/.bashrc"

            echo 'Appending ~/.bashrc'
            (
            cat << 'TERM'

# ABS improved shell history
shopt -s histappend         # append to the history file, don't overwrite it
HISTSIZE=10000              # cache    the last  10,000 commands
HISTFILESIZE=100000         # remember the last 100,000 commands
HISTCONTROL="ignoredups"    # ignore duplicates
HISTIGNORE="l:la:ll:ls:cd:clear:history:pwd" # ignore select simple commands

# if we are in a screen, this will get its name, with any slashes replaced with dashes
current_terminal_name=$(screen -ls | grep '(Attached)' | cut -d . -f 2 | cut -d '(' -f 1 | xargs | sed 's/\//-/g;s/^-//g')
if [[ -z "$current_terminal_name" ]]; then
    # not actively in a screen, so use the terminal name instead
    current_terminal_name=$(tty | sed 's/\//-/g;s/^-//g')
fi
HISTFILE="${HOME}/.bash_history/$current_terminal_name"    # bash_history as folder split by terminal name

# if we have already sourced this file, don't do it again
if [[ "${PROMPT_COMMAND}" != *"history"* ]]; then
    # append history as you go
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND/%;};}history -a"
    # also, build a history of other ttys
    ls "${HOME}/.bash_history/"* | grep -v "${HOME}/.bash_history/others" | grep -v "${HISTFILE}" | xargs cat > "${HOME}/.bash_history/others"
    # then read from the other ttys history, so our history is complete
    history -n "${HOME}/.bash_history/others"
fi

TERM
) >> "$HOME/.bashrc"

            # if we are in a screen, this will get its name, with any slashes replaced with dashes
            current_terminal_name=$(screen -ls | grep '(Attached)' | cut -d . -f 2 | cut -d '(' -f 1 | xargs | sed 's/\//-/g;s/^-//g')
            if [[ -z "$current_terminal_name" ]]; then
                # not actively in a screen, so use the terminal name instead
                current_terminal_name=$(tty | sed 's/\//-/g;s/^-//g')
            fi

            echo 'Move existing history file'
            if [ -f "${HOME}/.bash_history" ]; then
                mv "${HOME}/.bash_history" "$HOME/tmp_hist_file"
            fi
            mkdir "${HOME}/.bash_history"
            mv "$HOME/tmp_hist_file" "${HOME}/.bash_history/$current_terminal_name"

            echo 'Update live config'
            shopt -s histappend
            shopt -u histreedit
            shopt -u histverify
            export HISTSIZE=10000
            export HISTFILESIZE=100000
            export HISTCONTROL="ignoredups"
            export HISTIGNORE="l:la:ll:ls *:clear:history:pwd"
            export HISTFILE="${HOME}/.bash_history/$current_terminal_name"
            if [[ "${PROMPT_COMMAND}" != *"history"* ]]; then
                export PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND/%;};}history -a"
            fi
        else # HISTFILE is already customized
            echo 'WARNING: ~/.bash_history is not a file, history has already been customized, skipping.'
        fi

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
read -p 'Setup vim, colors, plugins, defaults, etc? [y/N]: ' set_vim
case $set_vim in
    [Yy]* )
        echo 'Appending ~/.bashrc'
        (
        cat << 'VIM'

# ABS default to using vim
export EDITOR=vim
export VISUAL=vim
# ABS less to render tabs as 4 characters
export LESS=Rx4

VIM
) >> "$HOME/.bashrc"

        echo 'Installing vim color "colorful256"'
        mkdir -p "${HOME}/.vim/colors"
        LOCATION=`dirname "$0"`
        cp "${LOCATION}/vim/colorful256.vim" "${HOME}/.vim/colors/colorful256.vim"

        echo 'Installing plugin manager "vim-plug"'
        mkdir -p "${HOME}/.vim/autoload"
        if [[ -n $(command -v "jq") ]]; then
            # prefer to download the latest release tag
            version=$(curl --silent 'https://api.github.com/repos/junegunn/vim-plug/releases/latest' | jq -r '.tag_name')
        fi
        if [[ -z "$version" ]]; then
            # but fallback to main branch
            version="master"
        fi
        curl --output "$HOME/.vim/autoload/plug.vim" --silent "https://raw.githubusercontent.com/junegunn/vim-plug/$version/plug.vim"

        echo 'Installing vimrc'
        if [[ -f "$HOME/.vimrc" ]] && [[ ! -f "$HOME/vimrc.backup.$curdate" ]]; then
            echo 'existing vimrc file detected, backing up'
            mv "$HOME/.vimrc" "$HOME/vimrc.backup.$curdate"
        fi
        cp "${LOCATION}/vim/vimrc" "${HOME}/.vimrc"

        echo 'Installing default plugins'
        vim +'PlugInstall --sync' +quitall
        ;;
    * )
        echo 'Skipping'
        ;;
esac

## ----------------------------------------------------------
#
#echo "----- Install GoAccess configuration ----------------"
#read -p 'Add GoAccess RC config file? [y/N]: ' set_gorc
#case $set_gorc in
#    [Yy]* )
#        echo 'Installing GoAccess RC'
#        LOCATION=`dirname "$0"`
#        cp "${LOCATION}/conf/goaccessrc" "${HOME}/.goaccessrc"
#        ;;
#    * )
#        echo 'Skipping'
#        ;;
#esac

# ----------------------------------------------------------

echo "----- Done ------------------------------------------"
echo "to take effect now, you need to run:"
echo "source ~/.bashrc"

