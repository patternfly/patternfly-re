#!/bin/sh

default()
{
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/_env.sh
  . $SCRIPT_DIR/_common.sh

  BUILD_DIR=$TRAVIS_BUILD_DIR
}

# Check prerequisites before continuing
#
prereqs()
{
  echo "This build is running against $TRAVIS_REPO_SLUG"

  if [ -n "$TRAVIS_TAG" ]; then
    echo "This build is running against $TRAVIS_TAG"

    # Get version from tag
    case "$TRAVIS_TAG" in
      $BUMP_NEXT_TAG_PREFIX* ) RELEASE_NEXT=1;;
      $BUMP_NEXT_CHAIN_TAG_PREFIX* ) RELEASE_NEXT=1;;
      $BUMP_CHAIN_TAG_PREFIX* ) RELEASE=1;;
      $BUMP_TAG_PREFIX* ) RELEASE=1;;
      *) echo "$TRAVIS_TAG is not a recognized format. Do not release!";;
    esac
  fi
}

usage()
{
cat <<- EEOOFF

    This script will build, publish, and release the repo.

    Note: Intended for use with Travis only.

    sh [-x] $SCRIPT [-h] -a|e|o|p|r|w|x

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    o       PatternFly Org
    p       PatternFly
    r       RCUE
    w       PatternFly Web Components
    x       Patternfly NG

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haeoprwx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         SWITCH=a;;
      e) PTNFLY_ENG_RELEASE=1;
         SWITCH=e;;
      o) PTNFLY_ORG=1;
         SWITCH=o;;
      p) PTNFLY=1;
         SWITCH=p;;
      r) RCUE=1;
         SWITCH=r;;
      w) PTNFLY_WC=1;
         SWITCH=w;;
      x) PTNFLY_NG=1;
         SWITCH=x;;
      \?) usage; exit 1;;
    esac
  done

  prereqs
  git_setup

  # Release must remove shrinkwrap prior to install; thus, the Travis install is turned off
  if [ -n "$RELEASE" ]; then
    sh -x $SCRIPT_DIR/release/_build.sh -$SWITCH
    check $? "Release failure"
  elif [ -n "$RELEASE_NEXT" ]; then
    sh -x $SCRIPT_DIR/release/_build-next.sh -$SWITCH
    check $? "Release failure"
  else
    build_install
    build
    build_test

    # Skip publish for pull requests and tags
    if [ "$TRAVIS_PULL_REQUEST" = "false" -a -z "$TRAVIS_TAG" ]; then
      if [ -n "$PTNFLY" -o -n "$PTNFLY_ANGULAR" -o -n "$PTNFLY_NG" -o -n "$PTNFLY_WC" ]; then
        sh -x $SCRIPT_DIR/_publish-branch.sh
        check $? "Publish failure"
      fi
    fi
  fi
}
