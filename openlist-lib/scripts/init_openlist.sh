#!/bin/bash

GIT_REPO="https://github.com/koljs/OpenList.git"
TAG_NAME=$(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags $GIT_REPO | tail -n 1 | cut -d'/' -f3)

echo "OpenList - ${TAG_NAME}"
rm -rf ./src
unset GIT_WORK_TREE
git clone --branch "$TAG_NAME" https://github.com/OpenListTeam/OpenList.git ./src
rm -rf ./src/.git

echo "Checking cloned source structure:"
ls -la ./src/

# Move the entire OpenList source to the parent directory
echo "Moving OpenList source files..."
mv -f ./src/* ../
rm -rf ./src

echo "Checking moved files in parent directory:"
ls -la ../

# Check if we have the main go.mod in the right place
if [ -f ../go.mod ]; then
    echo "Found go.mod in parent directory"
    cd ../
    go mod edit -replace github.com/djherbis/times@v1.6.0=github.com/jing332/times@latest
    echo "OpenList source initialization completed"
else
    echo "Error: go.mod not found after moving files"
    echo "Contents of parent directory:"
    ls -la ../
    exit 1
fi
