#!/bin/sh

# Setup env for use with GitHub
#
git_setup()
{
  echo "*** Setting up Git env"
  cd $BUILD_DIR

  # Add PatternFly Org as a remote
  git remote rm $REPO_NAME_PTNFLY_ORG
  git remote add $REPO_NAME_PTNFLY_ORG https://$AUTH_TOKEN@github.com/$REPO_SLUG_PTNFLY_ORG.git
  check $? "git add remote failure"

  # Add RCUE as the next remote
  git remote rm $REPO_NAME_RCUE
  git remote add $REPO_NAME_RCUE https://$AUTH_TOKEN@github.com/$REPO_SLUG_RCUE.git
  check $? "git add remote failure"
}

# Check prerequisites before continuing
#
merge_prereqs()
{
  echo "*** This build is running against $TRAVIS_REPO_SLUG"
  cd $BUILD_DIR

  # Skip for pull requests and tags
  if [ "$TRAVIS_PULL_REQUEST" != "false" -o -n "$TRAVIS_TAG" ]; then
    echo "*** This build is running against a pull request or tag! Exiting..."
    exit 0
  fi
}
