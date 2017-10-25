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

# Check prerequisites before continuing
#
prereqs()
{
  if [ "$TRAVIS_BRANCH" = "$RELEASE_DIST_BRANCH" ]; then
    echo "*** This script is running against $RELEASE_DIST_BRANCH. Do not run!"
    exit 0
  fi
}

# Run regression test
#
regression_test()
{
  echo "*** Running regression test"
  cd $BUILD_DIR

  if [ -s "backstop/test.js" ]; then
    node ./backstop/test
    check $? "Regression test failure"
  fi
}

usage()
{
cat <<- EEOOFF

    This script will run regression tests if available

    sh [-x] $SCRIPT [-h]

    Example: sh $SCRIPT

    OPTIONS:
    h       Display this message (default)

EEOOFF
}

# main()
{
  default

  while getopts h c; do
    case $c in
      h) usage; exit 0;;
      \?) usage; exit 1;;
    esac
  done

  prereqs
  regression_test
}
