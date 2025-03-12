#!/bin/bash

git filter-branch --env-filter '
if [ "$GIT_COMMITTER_NAME" = "Wilson Bilkovich (aider)" ]; then
    export GIT_COMMITTER_NAME="Wilson Bilkovich"
fi
if [ "$GIT_AUTHOR_NAME" = "Wilson Bilkovich (aider)" ]; then
    export GIT_AUTHOR_NAME="Wilson Bilkovich"
fi
' --tag-name-filter cat -- --all
