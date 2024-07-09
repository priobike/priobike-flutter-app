#!/bin/bash

# Fetch the latest Git tag
GIT_TAG=$(git tag --points-at HEAD)

# Check if the git tag contains "release"
if [[ $GIT_TAG == "release-"* ]]; then
  # Write the tag to a text file
  echo $GIT_TAG > git_tag.txt
fi

