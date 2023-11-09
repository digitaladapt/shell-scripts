#!/bin/bash

scriptRoot="$(dirname "$0")/.."

"$scriptRoot/thermal.sh" | "$scriptRoot/discord.sh" -c "yellow" -t "Thermal Status"

