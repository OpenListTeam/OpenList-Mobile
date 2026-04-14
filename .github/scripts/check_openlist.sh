#!/bin/bash

GIT_REPO="https://github.com/OpenListTeam/OpenList.git"

function compare_versions() {
  local v1="${1#v}"
  local v2="${2#v}"
  local max_len=0

  IFS='.' read -r -a v1_parts <<< "$v1"
  IFS='.' read -r -a v2_parts <<< "$v2"

  if [ "${#v1_parts[@]}" -gt "${#v2_parts[@]}" ]; then
    max_len="${#v1_parts[@]}"
  else
    max_len="${#v2_parts[@]}"
  fi

  for ((i=0; i<max_len; i++)); do
    local p1="${v1_parts[i]:-0}"
    local p2="${v2_parts[i]:-0}"

    p1=$(echo "$p1" | grep -oE '^[0-9]+' || echo 0)
    p2=$(echo "$p2" | grep -oE '^[0-9]+' || echo 0)

    if ((10#$p1 > 10#$p2)); then
      echo 1
      return
    fi

    if ((10#$p1 < 10#$p2)); then
      echo -1
      return
    fi
  done

  echo 0
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

echo "Latest OpenList version $LATEST_VER"

echo "openlist_version=$LATEST_VER" >> "$GITHUB_ENV"
# VERSION_FILE="$GITHUB_WORKSPACE/openlist_version.txt"

VER=$(cat "$VERSION_FILE")

if [ -z "$VER" ]; then
  VER="v3.25.1"
  echo "No version file, use default version ${VER}"
fi

echo "Current OpenList version: $VER"

COMPARE_RESULT=$(compare_versions "$VER" "$LATEST_VER")

if [ "$COMPARE_RESULT" -ge 0 ]; then
    echo "Current >= Latest"
    echo "openlist_update=0" >> "$GITHUB_ENV"
else
    echo "Current < Latest"
    echo "openlist_update=1" >> "$GITHUB_ENV"
fi
