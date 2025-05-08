#!/usr/bin/env bash

# the command used to initialize our subtree
#git subtree add --prefix=nodesource https://github.com/nodesource/distributions.git master --squash

# the command used to update our subtree
git subtree pull --prefix=nodesource https://github.com/nodesource/distributions.git master --squash

