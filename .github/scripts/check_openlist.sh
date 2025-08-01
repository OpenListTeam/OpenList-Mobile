#!/bin/bash

GIT_REPO="https://github.com/OpenListTeam/OpenList.git"

function to_int() {
    echo $(echo "$1" | grep -oE '[0-9]+' | tr -d '\n')
}

function get_latest_version() {
    echo $(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags $GIT_REPO | tail --lines=1 | cut --delimiter='/' --fields=3)
}

LATEST_VER=""
for index in $(seq 5)
do
    echo "Try to get latest version, index=$index"
    LATEST_VER=$(get_latest_version)
    if [ -z "$LATEST_VER" ]; then
      if [ "$index" -ge 5 ]; then
        echo "Failed to get latest version, exit"
        exit 1
      fi
      echo "Failed to get latest version, sleep 15s and retry"
      sleep 15
    else
      break
    fi

done

LATEST_VER_INT=$(to_int "$LATEST_VER")
echo "Latest OpenList version $LATEST_VER ${LATEST_VER_INT}"

echo "openlist_version=$LATEST_VER" >> "$GITHUB_ENV"
# VERSION_FILE="$GITHUB_WORKSPACE/openlist_version.txt"

VER=$(cat "$VERSION_FILE")

if [ -z "$VER" ]; then
  VER="v3.25.1"
  echo "No version file, use default version ${VER}"
fi

VER_INT=$(to_int $VER)

echo "Current OpenList version: $VER ${VER_INT}"


if [ "$VER_INT" -ge "$LATEST_VER_INT" ]; then
    echo "Current >= Latest"
    echo "openlist_update=0" >> "$GITHUB_ENV"
else
    echo "Current < Latest"
    echo "openlist_update=1" >> "$GITHUB_ENV"
fi
