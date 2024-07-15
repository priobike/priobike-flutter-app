#!/bin/bash

echo "Fetching the latest Git tag..."

# Setting the tag if it provided as an argument
GIT_TAG=$1

# Fetch the latest Git tag
if [[GIT_TAG == null]]; then
  echo "No tag provided. Fetching tag from the latest commit."
  GIT_TAG=$(git tag --points-at HEAD)
fi

# To check in ci script
echo $GIT_TAG

# Check if the git tag contains "release"
if [[ $GIT_TAG == "release-"* ]]; then
  # Write the tag to a text file
  echo $GIT_TAG > git_tag.txt
  echo git_tag.txt
fi
