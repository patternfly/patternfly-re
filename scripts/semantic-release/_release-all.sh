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
}

usage()
{
cat <<- EEOOFF

    This script is a wrapper for the legacy release-all.sh script to automate PatternFly releases.

    Currently, only RCUE is supported

    sh [-x] $SCRIPT [-h] -r

    Example: sh $SCRIPT -r

    OPTIONS:
    h       Display this message (default)
    r       RCUE

EEOOFF
}

# main()
{
  default

  if [ "$#" -eq 0 ]; then
    usage
    exit 1
  fi

  while getopts hr c; do
    case $c in
      h) usage; exit 0;;
      r) RCUE=1;
         SWITCH=-r;;
      \?) usage; exit 1;;
    esac
  done

  if [ -n "$RCUE" ]; then
    VERSION=`npm show patternfly version`
    $SCRIPT_DIR/../release/release-all.sh $SWITCH -v $VERSION
  fi
}
