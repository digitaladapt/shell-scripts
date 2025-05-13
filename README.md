# Shell Scipts

A collection of shell scripts that I like to have on my server,
the `setup` folder contains steps to quickly configure a new debian machine.

Many of the scripts use `config.sh`, which there is an example config for reference.
It can contain information like discord webhooks, drives to monitor storage usage, etc.

Most used scripts is the `*-all.sh` scripts, which are various git functions run across
a collection of locations. So you can be in a code folder containing multiple projects,
and run `status-all.sh` to get a concise summary of each codebase without having to go into each one.
