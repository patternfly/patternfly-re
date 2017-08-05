#!/bin/sh

default()
{
  SCRIPT=`basename $0`
  SCRIPT_DIR=`dirname $0`
  SCRIPT_DIR=`cd $SCRIPT_DIR; pwd`

  . $SCRIPT_DIR/_env.sh
  . $SCRIPT_DIR/_common.sh

  TMP_DIR="/tmp/patternfly-release"
  VERIFY_DIR="$TMP_DIR/patternfly-verify"
}

usage()
{
cat <<- EEOOFF

    This script will publish the shrinkwrap file to GitHub.

    Note: Intended for use with Travis only.

    sh [-x] $SCRIPT [-h]

    Example: sh $SCRIPT

    OPTIONS:
    h       Display this message (default)

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
    npm install $2
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

  while getopts haopr c; do
    case $c in
      h) usage; exit 0;;
      \?) usage; exit 1;;
    esac
  done

  verify $VERIFY_DIR $TRAVIS_BUILD_DIR
}
