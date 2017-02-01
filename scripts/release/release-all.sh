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

  BRANCH=$RELEASE_BRANCH
  TAG_PREFIX=$BUMP_TAG_PREFIX
  TMP_DIR="/tmp/patternfly-repos"
}

# Add tag to kick off version bump
#
# $1: Tag prefix
add_bump_tag()
{
  echo "*** Adding version bump tag"
  cd $BUILD_DIR

  git tag $1$VERSION
  check $? "git tag failure"

  git push origin tag $1$VERSION
  check $? "git push tag failure"
}

usage()
{
cat <<- EEOOFF

    This script will release the repo by creating a custom Git tag. Travis will run the appropriate scripts to
    automatically bump version numbers, build, shrinkwrap, test, install, and publish the release.

    When the release is complete, the custom Git tag is removed from GitHub. The custom tag is created using a clone so
    it won't persist in your local repo.

    If the release is successful, RCUE, Angular PatternFly, and PatternFly Org will be released as well. This is done
    by creating a Git tag for the next repo to be built.

    If 3.15.0 is provided as a version number; for example, the release will be tagged as v3.15.0.

    Release notes must be added via GitHub.

    Note: Builds can only be stopped via the Travis UI: https://travis-ci.org/patternfly

    sh [-x] $SCRIPT [-h|f|n] -a|e|o|p|r|w -v <version>

    Example: sh $SCRIPT -v 3.15.0 -e

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    o       PatternFly Org
    p       PatternFly
    r       PatternFly RCUE
    v       The version number (e.g., 3.15.0)
    w       PatternFly Web Components

    SPECIAL OPTIONS:
    f       Run against repo fork matching local username (e.g., `whoami`/patternfly)
    n       Release PF 'next' branches (e.g., PF4 alpha, beta, etc.)

EEOOFF
}

# main()
{
  # Source env.sh afer setting REPO_FORK
  if [ -z "$TRAVIS" ]; then
    while getopts haefnoprv:w c; do
      case $c in
        f) REPO_FORK=1;;
        \?) ;;
      esac
    done
    unset OPTIND
  fi

  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haefnoprv:w c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         BUILD_DIR=$TMP_DIR/angular-patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;;
      e) PTNFLY_ENG_RELEASE=1;
         BUILD_DIR=$TMP_DIR/patternfly-eng-release;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;;
      f) ;;
      n) RELEASE_NEXT=1;
         TAG_PREFIX=$BUMP_NEXT_TAG_PREFIX;;
      o) PTNFLY_ORG=1;
         BUILD_DIR=$TMP_DIR/patternfly-org;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ORG;;
      p) PTNFLY=1;
         BUILD_DIR=$TMP_DIR/patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY;;
      r) PTNFLY_RCUE=1;
         BUILD_DIR=$TMP_DIR/rcue;
         REPO_SLUG=$REPO_SLUG_RCUE;;
      v) VERSION=$OPTARG;;
      w) PTNFLY_WC=1;
         BUILD_DIR=$TMP_DIR/patternfly-webcomponents;
         REPO_SLUG=$REPO_SLUG_PTNFLY_WC;;
      \?) usage; exit 1;;
    esac
  done

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  # Release PF 'next' branches
  if [ -n "$RELEASE_NEXT" ]; then
    if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_RCUE" ]; then
      BRANCH=$NEXT_BRANCH
    fi
  fi

  setup_repo $REPO_SLUG $BRANCH
  add_bump_tag $TAG_PREFIX
  rm -rf $TMP_DIR

  echo "*** Travis build history: https://travis-ci.org/patternfly"
}
