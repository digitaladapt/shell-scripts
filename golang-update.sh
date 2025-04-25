#!/usr/bin/env bash

# the command used to initialize our subtree
#git subtree add --prefix golang-install https://github.com/canha/golang-tools-install-script.git master --squash

# the command used to update our subtree
git subtree pull --prefix golang-install https://github.com/canha/golang-tools-install-script.git master --squash

