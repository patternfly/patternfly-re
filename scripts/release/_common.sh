#!/bin/sh

# Setup env for use with GitHub
#
git_setup()
{
  echo "*** Setting up Git env"
  cd $BUILD_DIR

  # Add Angular Patternfly as a remote
  git remote rm apf
  git remote add apf https://$AUTH_TOKEN@github.com/$REPO_SLUG_PTNFLY_ANGULAR.git
  check $? "git add remote failure"

  # Add Patternfly as a remote
  git remote rm pf
  git remote add pf https://$AUTH_TOKEN@github.com/$REPO_SLUG_PTNFLY.git
  check $? "git add remote failure"

  # Add Patternfly Org as a remote
  git remote rm pfo
  git remote add pfo https://$AUTH_TOKEN@github.com/$REPO_SLUG_PTNFLY_ORG.git
  check $? "git add remote failure"

  # Add RCUE as the next remote
  git remote rm rcue
  git remote add rcue https://$AUTH_TOKEN@github.com/$REPO_SLUG_RCUE.git
  check $? "git add remote failure"

  # Fetch to test if tag exists
  git fetch --tags
  check $? "Fetch tags failure"
}

# Clone local repo and checkout branch
#
# $1: Repo slug
# $2: Repo branch
setup_repo() {
  DIR=$TMP_DIR/`basename $1`
  echo "*** Setting up local repo $DIR"

  rm -rf $DIR
  mkdir -p $TMP_DIR
  cd $TMP_DIR

  git clone https://github.com/$1.git
  check $? "git clone failure"

  cd $DIR
  git checkout $2
  if [ "$?" -ne 0 ]; then
    git checkout -B $2
  fi
  check $? "git checkout failure"
}
