#!/bin/bash

# the command used to initialize our subtree
#git subtree add --prefix ssh-ident-ccontavalli https://github.com/ccontavalli/ssh-ident.git master --squash

# the command used to update our subtree
git subtree pull --prefix ssh-ident-ccontavalli https://github.com/ccontavalli/ssh-ident.git master --squash

