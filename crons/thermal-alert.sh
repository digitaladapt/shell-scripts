#!/usr/bin/env bash

# degrees in Celsius which we regard as too high, defaults to config
alertLevel="$1"

# load in defaults from config
scriptRoot="$(dirname "$0")/.."
configFile="$scriptRoot/config.sh"
if [[ -f "$configFile" ]]; then
    source "$configFile"

    if [[ -z "$alertLevel" ]]; then
        alertLevel="$THERMAL_ALERT"
    fi
fi

# get current status
thermal=$("$scriptRoot/thermal.sh" "$alertLevel")
alert="$?"

if [[ "0" -ne "$alert" ]]; then
    # if currently in an alert status
    alertLevelF=`echo "scale=1 ; $alertLevel * 9 / 5 + 32" | bc -l`
    "$scriptRoot/discord.sh" -c "red" -t "Thermal Alert" "$thermal" $'\n' "above threshold $alertLevel C ($alertLevelF F)"
    touch "$HOME/.thermal.alert"
elif [[ -f "$HOME/.thermal.alert" ]]; then
    # if previously in an alert status
    alertLevelF=`echo "scale=1 ; $alertLevel * 9 / 5 + 32" | bc -l`
    "$scriptRoot/discord.sh" -c "orange" -t "Thermal Alert" "$thermal" $'\n' "previously above threshold $alertLevel C ($alertLevelF F)"
    rm "$HOME/.thermal.alert"
fi

