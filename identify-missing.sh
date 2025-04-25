#!/usr/bin/env bash

# identify-missing.sh ./* < file_list.txt
# will list all files from file/input which is not present in the given loction.

while IFS= read -r name; do
  [ -n "$(find . -name "$name" -print | head -n 1)" ] || printf '%s\n' "$name"
done

