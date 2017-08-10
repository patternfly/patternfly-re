#!/bin/sh

default()
{
  PATH=/usr/local/bin:/usr/bin:/bin:$PATH
  export PATH

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  BRANCH=$RELEASE_BRANCH
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

    sh [-x] $SCRIPT [-h|f|n|s] -a|e|o|p|r|w|x -v <version>

    Example: sh $SCRIPT -v 3.15.0 -e

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly (DISABLED for semantic release)
    e       PatternFly Eng Release (DISABLED for semantic release)
    o       PatternFly Org
    p       PatternFly (DISABLED for semantic release)
    r       RCUE
    v       The version number (e.g., 3.15.0)
    w       PatternFly Web Components (DISABLED for semantic release)
    x       Patternfly NG (DISABLED for semantic release)

    SPECIAL OPTIONS:
    s       Skip chained releases.
    f       Run against repo fork matching local username (e.g., `whoami`/patternfly)
    n       Release PF 'next' branches (e.g., PF4 alpha, beta, etc.)

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haefnoprsv:wx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1; usage; exit1;; # DISABLED
      e) PTNFLY_ENG_RELEASE=1; usage; exit1;; # DISABLED
      f) REPO_FORK=1;;
      n) RELEASE_NEXT=1;;
      o) PTNFLY_ORG=1;;
      p) PTNFLY=1; usage; exit1;; # DISABLED
      r) RCUE=1;;
      s) SKIP_CHAINED_RELEASE=1;;
      v) VERSION=$OPTARG;;
      w) PTNFLY_WC=1; usage; exit1;; # DISABLED
      x) PTNFLY_NG=1; usage; exit1;; # DISABLED
      \?) usage; exit 1;;
    esac
  done

  # Source env.sh afer setting REPO_FORK
  if [ -n "$REPO_FORK" ]; then
    default
  fi

  if [ -n "$PTNFLY_ANGULAR" ]; then
    BUILD_DIR=$TMP_DIR/angular-patternfly
    REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR
  fi
  if [ -n "$PTNFLY_ENG_RELEASE" ]; then
    BUILD_DIR=$TMP_DIR/patternfly-eng-release
    REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE
  fi
  if [ -n "$PTNFLY_ORG" ]; then
    BUILD_DIR=$TMP_DIR/patternfly-org
    REPO_SLUG=$REPO_SLUG_PTNFLY_ORG
  fi
  if [ -n "$PTNFLY" ]; then
    BUILD_DIR=$TMP_DIR/patternfly
    REPO_SLUG=$REPO_SLUG_PTNFLY
  fi
  if [ -n "$RCUE" ]; then
    BUILD_DIR=$TMP_DIR/rcue
    REPO_SLUG=$REPO_SLUG_RCUE
  fi
  if [ -n "$PTNFLY_WC" ]; then
    BUILD_DIR=$TMP_DIR/patternfly-webcomponents
    REPO_SLUG=$REPO_SLUG_PTNFLY_WC
  fi
  if [ -n "$PTNFLY_NG" ]; then
    BUILD_DIR=$TMP_DIR/patternfly-ng
    REPO_SLUG=$REPO_SLUG_PTNFLY_NG
  fi

  if [ -z "$VERSION" -o -z "$REPO_SLUG" ]; then
    usage
    exit 1
  fi

  # Release PF Next branches
  if [ -n "$RELEASE_NEXT" ]; then
    if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$RCUE" ]; then
      BRANCH=$NEXT_BRANCH
    fi
  fi

  if [ -n "$SKIP_CHAINED_RELEASE" ]; then
    if [ -n "$RELEASE_NEXT" ]; then
      TAG_PREFIX=$BUMP_NEXT_TAG_PREFIX
    else
      TAG_PREFIX=$BUMP_TAG_PREFIX
    fi
  else
    if [ -n "$RELEASE_NEXT" ]; then
      TAG_PREFIX=$BUMP_NEXT_CHAIN_TAG_PREFIX
    else
      TAG_PREFIX=$BUMP_CHAIN_TAG_PREFIX
    fi
  fi

  setup_repo $REPO_SLUG $BRANCH
  add_bump_tag $TAG_PREFIX
  rm -rf $TMP_DIR

  echo "*** Travis build history: https://travis-ci.org/patternfly"
}
