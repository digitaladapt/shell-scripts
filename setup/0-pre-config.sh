#!/usr/bin/env bash

read -p 'Install git and vim? [y/N]: ' response
case "${response}" in
    [Yy]* )
        # before we can begin, we need what should have already been installed
        sudo apt install git vim -y
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Enable available aliases within your ~/.bashrc? [y/N]: ' response
case "${response}" in
    [Yy]* )
        # enable available aliases
        sed -i -e 's/#alias/alias/g' "${HOME}/.bashrc"
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

# ----------------------------------------------------------

read -p 'Install scripts into your ~/bin? [y/N]: ' response
case "${response}" in
    [Yy]* )
        # setup symlinks, if not installed in users bin directory
        # need absolute path, so the symbolic links will be created correctly.
        script_dir=$(readlink -f "$0" | xargs dirname | xargs dirname)

	# --- home bin folder ---
        if [[ ! -d "${HOME}/bin" ]]; then
            echo 'making personal bin directory'
            mkdir -p "${HOME}/bin"
        fi

        # --- general scripts ---
        if [[ ! -f "${HOME}/bin/4-public-ip.sh" ]]; then
            echo 'installing 4-public-ip.sh'
            ln -s "${script_dir}/4-public-ip.sh" "${HOME}/bin/4-public-ip.sh"
        fi

        if [[ ! -f "${HOME}/bin/6-public-ip.sh" ]]; then
            echo 'installing 6-public-ip.sh'
            ln -s "${script_dir}/6-public-ip.sh" "${HOME}/bin/6-public-ip.sh"
        fi

        if [[ ! -f "${HOME}/bin/docker-ps.sh" ]]; then
            echo 'installing docker-ps.sh'
            ln -s "${script_dir}/docker-ps.sh" "${HOME}/bin/docker-ps.sh"
        fi

        if [[ ! -f "${HOME}/bin/delay.sh" ]]; then
            echo 'installing delay.sh'
            ln -s "${script_dir}/delay.sh" "${HOME}/bin/delay.sh"
        fi

        if [[ ! -f "${HOME}/bin/enumerate.sh" ]]; then
            echo 'installing enumerate.sh'
            ln -s "${script_dir}/enumerate.sh" "${HOME}/bin/enumerate.sh"
        fi

        if [[ ! -f "${HOME}/bin/is-restart-needed.sh" ]]; then
            echo 'installing is-restart-needed.sh'
            ln -s "${script_dir}/is-restart-needed.sh" "${HOME}/bin/is-restart-needed.sh"
        fi

        if [[ ! -f "${HOME}/bin/named-cat.sh" ]]; then
            echo 'installing named-cat.sh'
            ln -s "${script_dir}/named-cat.sh" "${HOME}/bin/named-cat.sh"
        fi

        if [[ ! -f "${HOME}/bin/restart-if-needed.sh" ]]; then
            echo 'installing restart-if-needed.sh'
            ln -s "${script_dir}/restart-if-needed.sh" "${HOME}/bin/restart-if-needed.sh"
        fi

        if [[ ! -f "${HOME}/bin/upgrade.sh" ]]; then
            echo 'installing upgrade.sh'
            ln -s "${script_dir}/upgrade.sh" "${HOME}/bin/upgrade.sh"
        fi

        # --- git related scripts ---
        if [[ ! -f "${HOME}/bin/fetch-all.sh" ]]; then
            echo 'installing fetch-all.sh'
            ln -s "${script_dir}/fetch-all.sh" "${HOME}/bin/fetch-all.sh"
        fi

        if [[ ! -f "${HOME}/bin/list-all.sh" ]]; then
            echo 'installing list-all.sh'
            ln -s "${script_dir}/list-all.sh" "${HOME}/bin/list-all.sh"
        fi

        if [[ ! -f "${HOME}/bin/pull-all.sh" ]]; then
            echo 'installing pull-all.sh'
            ln -s "${script_dir}/pull-all.sh" "${HOME}/bin/pull-all.sh"
        fi

        if [[ ! -f "${HOME}/bin/status-all.sh" ]]; then
            echo 'installing status-all.sh'
            ln -s "${script_dir}/status-all.sh" "${HOME}/bin/status-all.sh"
        fi
        ;;
    * )
        echo 'Skipping'
        ;;
esac
echo ''

