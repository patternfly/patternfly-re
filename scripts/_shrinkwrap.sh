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

# Clean shrinkwrap
#
clean_shrinkwrap()
{
  if [ -s $SHRINKWRAP_JSON ]; then
    rm -f $SHRINKWRAP_JSON
  fi
}

# Shrink wrap npm and run vulnerability test
#
shrinkwrap()
{
  echo "*** Shrink wrapping $SHRINKWRAP_JSON"
  cd $BUILD_DIR

  # Only include production dependencies with shrinkwrap
  npm prune --production

  npm shrinkwrap
  check $? "npm shrinkwrap failure"

  # Restore all packages for testing with karma, nsp, etc.
  npm install
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

# main()
{
  default

  while getopts h c; do
    case $c in
      h) usage; exit 0;;
      \?) usage; exit 1;;
    esac
  done

  clean_shrinkwrap
  shrinkwrap
}
