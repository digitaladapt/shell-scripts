#!/usr/bin/env bash

# check if we have added the git remote already
hasRemote=$(git remote -vv | grep 'gitprompt' || echo 'nope')

if [[ "$hasRemote" == "nope" ]]; then
    # add the remote so we can do a partial subtree
    git remote add -f -t master --no-tags gitprompt https://github.com/git/git.git
else
    # clear out existing git-prompt folder, so we can rebuild it
    git rm -rf git-prompt
fi

# update our partial subtree
git read-tree --prefix=git-prompt/ -u gitprompt/master:contrib/completion
git commit

