#!/bin/bash

scriptRoot="$(dirname "$0")/.."

thermal=$("$scriptRoot/thermal.sh")

"$scriptRoot/discord.sh" "$thermal"

