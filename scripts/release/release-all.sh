#!/bin/sh

default()
{
  PATH=/bin:/usr/bin:/usr/local/bin:$PATH
  export PATH

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  TMP_DIR="/tmp/$SCRIPT.$$"
  BUILD_DIR="$TMP_DIR/repo"
}

# Add tag to kick off version bump
#
add_bump_tag()
{
  echo "*** Adding version bump tag"
  cd $BUILD_DIR

  git tag $BUMP_TAG_PREFIX$VERSION
  check $? "git tag failure"

  git push origin tag $BUMP_TAG_PREFIX$VERSION
  check $? "git push failure"
}

# Setup local repo
#
# $1: Repo slug
setup_repo() {
  echo "*** Setting up local repo $BUILD_DIR"
  mkdir -p $TMP_DIR
  cd $TMP_DIR

  git clone https://github.com/$1.git
  check $? "git clone failure"
  cd $BUILD_DIR

  git checkout master
  check $? "git checkout failure"
}

usage()
{
cat <<- EEOOFF

    This script will release the repo by creating a custom Git tag. Travis will run the appropriate scripts to
    automatically bump version numbers, build, shrinkwrap, test, install, and publish the release.

    When the release is complete, the custom Git tag is removed from GitHub. The custom tag is created using a clone so
    it won't persist in your local repo.

    If the release is successful, RCUE, Angular Patternfly, and Patternfly Org will be released as well. This is done
    by creating a Git tag for the next repo to be built.

    If 3.15.0 is provided as a version number; for example, the release will be tagged as v3.15.0.

    Release notes must be added via GitHub.

    Note: Builds can only be stopped via the Travis UI: https://travis-ci.org/patternfly

    sh [-x] $SCRIPT [-h] -a|e|o|p|r -v <version>

    Example: sh $SCRIPT -v 3.15.0

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       Patternfly Eng Release
    o       PatternFly Org
    p       PatternFly
    r       PatternFly RCUE
    v       The version number (e.g., 3.15.0)
    w       Patternfly Web Components (not chained with other releases)

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haeoprv: c; do
    case $c in
      h) usage; exit 0;;
      a) REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;;
      e) REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;;
      o) REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;;
      p) REPO_SLUG=$REPO_SLUG_PTNFLY;;
      r) REPO_SLUG=$REPO_SLUG_RCUE;;
      v) VERSION=$OPTARG;;
      w) REPO_SLUG=$REPO_SLUG_PTNFLY_WEB_COMPS;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  setup_repo $REPO_SLUG
  add_bump_tag
  rm -rf $TMP_DIR

  echo "*** Travis build history: https://travis-ci.org/patternfly"
}
