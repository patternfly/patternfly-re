#!/bin/sh

default()
{
  # Add paths to env (non-Travis build)
  if [ -z "$TRAVIS" ]; then
    PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH
  fi

  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/../_env.sh
  . $SCRIPT_DIR/../_common.sh
  . $SCRIPT_DIR/_common.sh

  BRANCH=$RELEASE_DIST_BRANCH
  TMP_DIR="/tmp/patternfly-releases"
}

# Publish npm
#
publish_npm()
{
  echo "*** Publishing npm"
  cd $BUILD_DIR

  NPM_FILE=".npmrc"
  if [ -n "$NPM_TOKEN" -a ! -f "$NPM_FILE" ]; then
    echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > $NPM_FILE
  fi

  # Log into npm if not already logged in
  WHOAMI=`npm whoami`
  if [ "$WHOAMI" != "patternfly-build" -a -n "$NPM_USER" -a -n "$NPM_PWD" ]; then
    printf "$NPM_USER\n$NPM_PWD\n$NPM_USER@redhat.com" | npm login
    check $? "npm login failure"
  fi

  # Tag PF 'next' release: https://medium.com/@mbostock/prereleases-and-npm-e778fc5e2420#.s6a099w69
  if [ -n "$TAG_NEXT" ]; then
    TAG_FLAG="-tag next"
  fi

  JUNK=`grep '"name": "@' package.json`
  if [ "$?" -eq 0 ]; then
    ACCESS_FLAG="--access public"
  fi

  npm publish $ACCESS_FLAG $TAG_FLAG
  check $? "npm publish failure"
}

usage()
{
cat <<- EEOOFF

    This script will npm publish from the latest repo clone or Travis build.

    sh [-x] $SCRIPT [-h|b|n|s] -a|e|p|r|w|x

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    p       PatternFly
    r       RCUE
    w       PatternFly Web Components
    x       PatternFly NG

    SPECIAL OPTIONS:
    b       The branch to publish (e.g., $NEXT_BRANCH)
    n       Release PF 'next' branches (e.g., PF4 alpha, beta, etc.)
    s       Skip new clone (e.g., to rebuild repo)

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hab:enprswx c; do
    case $c in
      h) usage; exit 0;;
      a) BUILD_DIR=$TMP_DIR/angular-patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ANGULAR;;
      b) BRANCH=$OPTARG;;
      e) BUILD_DIR=$TMP_DIR/patternfly-eng-release;
         REPO_SLUG=$REPO_SLUG_PTNFLY_ENG_RELEASE;;
      n) TAG_NEXT=1;;
      p) BUILD_DIR=$TMP_DIR/patternfly;
         REPO_SLUG=$REPO_SLUG_PTNFLY;;
      s) SKIP_SETUP=1;;
      r) BRANCH=$RELEASE_BRANCH
         BUILD_DIR=$TMP_DIR/rcue;
         REPO_SLUG=$REPO_SLUG_RCUE;;
      w) BUILD_DIR=$TMP_DIR/patternfly-webcomponents;
         REPO_SLUG=$REPO_SLUG_PTNFLY_WC;;
      x) BUILD_DIR=$TMP_DIR/patternfly-ng;
         REPO_SLUG=$REPO_SLUG_PTNFLY_NG;;
      \?) usage; exit 1;;
    esac
  done

  # Publish from the latest repo clone or Travis build
  if [ -n "$TRAVIS_BUILD_DIR" ]; then
    BUILD_DIR=$TRAVIS_BUILD_DIR
  fi
  if [ -z "$SKIP_SETUP" ]; then
    setup_repo $REPO_SLUG $BRANCH
  fi

  publish_npm

  if [ -z "$TRAVIS" ]; then
    echo "*** Remove $TMP_DIR directory manually after testing"
  fi
}
