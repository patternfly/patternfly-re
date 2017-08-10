#!/bin/sh

# Check prerequisites before continuing
#
merge_prereqs()
{
  echo "*** This build is running against $TRAVIS_REPO_SLUG"
  cd $BUILD_DIR

  # Skip for pull requests and tags
  if [ "$TRAVIS_PULL_REQUEST" = "false" -a -z "$TRAVIS_TAG" ]; then
    echo "*** This build is running against a pull request or tag! Exiting..."
    exit 1
  fi
}
