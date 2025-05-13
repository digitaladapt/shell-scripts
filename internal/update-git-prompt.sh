#!/usr/bin/env bash

# the command used to initialize our partial subtree
#git remote add -f -t master --no-tags gitprompt https://github.com/git/git.git
#git read-tree --prefix=git-prompt/ -u gitprompt/master:contrib/completion
#git commit

# the command used to update our partial subtree
git rm -rf git-prompt
git read-tree --prefix=git-prompt/ -u gitprompt/master:contrib/completion
git commit

