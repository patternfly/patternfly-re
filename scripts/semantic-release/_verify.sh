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

  BUILD_DIR=$TRAVIS_BUILD_DIR
  TMP_DIR="/tmp/patternfly-releases"
}

usage()
{
cat <<- EEOOFF

    This script will verify npm and bower installs

    sh [-x] $SCRIPT [-h] -a|e|p|w|x

    Example: sh $SCRIPT -p

    OPTIONS:
    h       Display this message (default)
    a       Angular PatternFly
    e       PatternFly Eng Release
    p       PatternFly
    w       PatternFly Web Components
    x       PatternFly NG

EEOOFF
}

# Verify npm and bower installs prior to publish step
#
# $1: Verify directory
# $2: Build directory
verify()
{
  echo "*** Verifying install"

  rm -rf $1
  mkdir -p $1
  cd $1

  if [ -s "$2/$PACKAGE_JSON" ]; then
    # Using pack to avoid installing a softlink
    npm install `npm pack $2`
    check $? "npm install failure"

    if [ ! -d "$1"/node_modules ]; then
      check 1 "npm install failure: node_modules directory expected"
    fi
  fi
  if [ -s "$2/$BOWER_JSON" ]; then
    cp $2/$BOWER_JSON .
    bower install
    check $? "bower install failure"
  fi
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts haepwx c; do
    case $c in
      h) usage; exit 0;;
      a) PTNFLY_ANGULAR=1;
         VERIFY_DIR="$TMP_DIR/angular-patternfly-verify";;
      e) PTNFLY_ENG_RELEASE=1;
         VERIFY_DIR="$TMP_DIR/patternfly-eng-release-verify";;
      p) PTNFLY=1;
         VERIFY_DIR="$TMP_DIR/patternfly-verify";;
      w) PTNFLY_WC=1;
         VERIFY_DIR="$TMP_DIR/patternfly-webcomponents-verify";;
      x) PTNFLY_NG=1;
         VERIFY_DIR="$TMP_DIR/patternfly-ng";;
      \?) usage; exit 1;;
    esac
  done

  if [ -n "$PTNFLY_NG" ]; then
    verify $VERIFY_DIR $BUILD_DIR/dist
  else
    verify $VERIFY_DIR $BUILD_DIR
  fi
}
