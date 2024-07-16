#!/bin/bash

echo "Setting the latest Git tag..."

# Setting the tag if it provided as an argument
GIT_TAG=$1

# To check in ci script
echo $GIT_TAG

# Check if the git tag contains "release"
if [[ $GIT_TAG == "release-"* ]]; then
  # Write the tag to a text file
  echo $GIT_TAG > git_tag.txt
  cat git_tag.txt
fi
